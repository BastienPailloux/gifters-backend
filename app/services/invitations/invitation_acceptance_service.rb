# Service pour gérer l'acceptation d'invitations
module Invitations
  class InvitationAcceptanceService
    include Dry::Transaction

    step :validate_input
    step :resolve_users
    step :process_memberships
    step :send_notifications
    step :prepare_response

    private

    def validate_input(input)
      contract = AcceptInvitationContract.new
      result = contract.call(input)

      if result.success?
        Success(result.to_h)
      else
        Failure(
          success: false,
          message: 'Validation failed',
          errors: result.errors.to_h
        )
      end
    end

    def resolve_users(input)
      current_user = input[:current_user]
      user_ids = input[:user_ids]
      invitation = input[:invitation]

      users_to_add = []
      errors = []

      user_ids.each do |user_id|
        if user_id == current_user.id
          users_to_add << current_user
        else
          begin
            child = User.find(user_id)
            if current_user.can_access_as_parent?(child)
              users_to_add << child
            else
              errors << { user_id: user_id, error: 'Not authorized to add this user' }
            end
          rescue ActiveRecord::RecordNotFound
            errors << { user_id: user_id, error: 'User not found' }
          end
        end
      end

      Success(
        invitation: invitation,
        current_user: current_user,
        users_to_add: users_to_add,
        errors: errors
      )
    end

    def process_memberships(input)
      invitation = input[:invitation]
      users_to_add = input[:users_to_add]
      errors = input[:errors]

      results = []

      users_to_add.each do |user|
        if user.groups.include?(invitation.group)
          errors << {
            user_id: user.id,
            user_name: user.name,
            error: 'Already a member of this group'
          }
          next
        end

        membership = invitation.group.add_user(user, invitation.role)

        if membership.persisted?
          results << {
            user: user,
            membership: membership,
            message: "Successfully joined the group #{invitation.group.name}"
          }
        else
          errors << {
            user_id: user.id,
            user_name: user.name,
            errors: membership.errors.full_messages
          }
        end
      end

      if results.any?
        Success(
          invitation: invitation,
          results: results,
          errors: errors
        )
      elsif errors.any? && errors.all? { |e| e[:error] == 'Already a member of this group' }
        # Utilisateur(s) déjà membre(s) : succès pour permettre la redirection vers le groupe
        Success(
          invitation: invitation,
          results: [],
          errors: errors,
          already_member: true
        )
      else
        Failure(
          success: false,
          message: 'No users were added to the group',
          errors: errors
        )
      end
    end

    def send_notifications(input)
      invitation = input[:invitation]
      results = input[:results]

      results.each do |result|
        notify_admins_about_new_member(invitation, result[:user])
      end

      Success(input)
    end

    def prepare_response(input)
      results = input[:results]
      errors = input[:errors]
      group_json = input[:invitation].group.as_json(only: [:id, :name])

      if input[:already_member]
        response = {
          success: true,
          already_member: true,
          message: 'You are already a member of this group',
          group: group_json
        }
      else
        response = {
          success: true,
          message: "#{results.size} user(s) successfully joined the group",
          results: results.map do |r|
            {
              user_id: r[:user].id,
              user_name: r[:user].name,
              message: r[:message]
            }
          end,
          errors: errors.presence,
          group: group_json
        }
      end

      Success(response)
    end

    def notify_admins_about_new_member(invitation, user)
      if Rails.env.test?
        InvitationMailer.invitation_accepted(invitation, user).deliver_now
      else
        InvitationMailer.invitation_accepted(invitation, user).deliver_later
      end
    end
  end
end
