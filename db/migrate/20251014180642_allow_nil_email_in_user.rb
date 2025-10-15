class AllowNilEmailInUser < ActiveRecord::Migration[8.0]
  def up
    # Supprimer l'ancien index unique
    remove_index :users, :email

    # Modifier la colonne pour permettre NULL et changer le default
    change_column_default :users, :email, from: "", to: nil
    change_column_null :users, :email, true

    # Créer un nouvel index partiel qui ignore les NULL
    # Cela permet d'avoir plusieurs users avec email = NULL
    # mais garantit l'unicité pour les emails non-NULL
    add_index :users, :email, unique: true, where: "email IS NOT NULL"
  end

  def down
    # Revenir à l'état précédent
    remove_index :users, :email
    change_column_null :users, :email, false
    change_column_default :users, :email, from: nil, to: ""
    add_index :users, :email, unique: true
  end
end
