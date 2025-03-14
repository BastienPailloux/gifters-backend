# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Nettoyer la base de données existante (à commenter en production)
puts "Nettoyage de la base de données..."
GiftIdea.destroy_all
Invitation.destroy_all
Membership.destroy_all
Group.destroy_all
User.destroy_all
puts "Base de données nettoyée."

# Création des utilisateurs
puts "Création des utilisateurs..."
admin = User.create!(
  name: "Admin",
  email: "admin@example.com",
  password: "password",
  birthday: Date.new(1990, 1, 15),
  gender: "male"
)

alice = User.create!(
  name: "Alice Dupont",
  email: "alice@example.com",
  password: "password",
  birthday: Date.new(1992, 5, 20),
  gender: "female"
)

bob = User.create!(
  name: "Bob Martin",
  email: "bob@example.com",
  password: "password",
  birthday: Date.new(1985, 9, 10),
  gender: "male"
)

charlie = User.create!(
  name: "Charlie Dubois",
  email: "charlie@example.com",
  password: "password",
  birthday: Date.new(1988, 12, 25),
  gender: "male"
)

diane = User.create!(
  name: "Diane Petit",
  email: "diane@example.com",
  password: "password",
  birthday: Date.new(1995, 7, 18),
  gender: "female"
)

users = [admin, alice, bob, charlie, diane]
puts "#{User.count} utilisateurs créés."

# Création des groupes
puts "Création des groupes..."
family_group = Group.create!(
  name: "Famille Dupont",
  description: "Groupe pour la famille Dupont"
)

friends_group = Group.create!(
  name: "Amis Proches",
  description: "Groupe pour les amis proches"
)

work_group = Group.create!(
  name: "Collègues de Bureau",
  description: "Groupe pour les collègues du bureau"
)
puts "#{Group.count} groupes créés."

# Création des memberships
puts "Création des memberships..."
# Groupe Famille
Membership.create!(user: admin, group: family_group, role: "admin")
Membership.create!(user: alice, group: family_group, role: "admin")
Membership.create!(user: bob, group: family_group, role: "member")
Membership.create!(user: charlie, group: family_group, role: "member")

# Groupe Amis
Membership.create!(user: admin, group: friends_group, role: "admin")
Membership.create!(user: bob, group: friends_group, role: "admin")
Membership.create!(user: charlie, group: friends_group, role: "member")
Membership.create!(user: diane, group: friends_group, role: "member")

# Groupe Travail
Membership.create!(user: admin, group: work_group, role: "admin")
Membership.create!(user: alice, group: work_group, role: "member")
Membership.create!(user: diane, group: work_group, role: "member")
puts "#{Membership.count} memberships créées."

# Création des invitations
puts "Création des invitations..."
Invitation.create!(
  group: family_group,
  created_by: admin,
  role: "member"
)

Invitation.create!(
  group: friends_group,
  created_by: bob,
  role: "member"
)

Invitation.create!(
  group: work_group,
  created_by: admin,
  role: "member"
)
puts "#{Invitation.count} invitations créées."

# Création des idées de cadeaux
puts "Création des idées de cadeaux..."
# Pour Alice
livre_cuisine = GiftIdea.new(
  title: "Livre de cuisine végétarienne",
  description: "Un livre avec des recettes végétariennes du monde entier",
  price: 25.99,
  link: "https://example.com/livre-cuisine",
  image_url: "https://example.com/image-livre.jpg",
  created_by: bob,
  status: "proposed"
)
livre_cuisine.recipients = [alice]
livre_cuisine.save!

coffret_the = GiftIdea.new(
  title: "Coffret de thés bio",
  description: "Assortiment de thés biologiques de différentes saveurs",
  price: 39.99,
  link: "https://example.com/coffret-thes",
  image_url: "https://example.com/image-the.jpg",
  created_by: charlie,
  status: "buying"
)
coffret_the.recipients = [alice]
coffret_the.save!

# Pour Bob
bieres = GiftIdea.new(
  title: "Set de bières artisanales",
  description: "Ensemble de 6 bières artisanales de différentes brasseries",
  price: 32.50,
  link: "https://example.com/bieres-artisanales",
  image_url: "https://example.com/image-bieres.jpg",
  created_by: alice,
  status: "proposed"
)
bieres.recipients = [bob]
bieres.save!

enceinte = GiftIdea.new(
  title: "Enceinte Bluetooth portable",
  description: "Enceinte portable avec une autonomie de 20 heures",
  price: 79.99,
  link: "https://example.com/enceinte-bluetooth",
  image_url: "https://example.com/image-enceinte.jpg",
  created_by: diane,
  status: "buying"
)
enceinte.recipients = [bob]
enceinte.save!

# Pour Charlie
casque = GiftIdea.new(
  title: "Casque audio sans fil",
  description: "Casque avec réduction de bruit active",
  price: 149.99,
  link: "https://example.com/casque-audio",
  image_url: "https://example.com/image-casque.jpg",
  created_by: bob,
  status: "proposed"
)
casque.recipients = [charlie]
casque.save!

whisky = GiftIdea.new(
  title: "Set de dégustation de whiskys",
  description: "Coffret avec 4 whiskys du monde et verres de dégustation",
  price: 89.99,
  link: "https://example.com/whisky-set",
  image_url: "https://example.com/image-whisky.jpg",
  created_by: admin,
  status: "bought"
)
whisky.recipients = [charlie]
whisky.save!

# Pour Diane
beaute = GiftIdea.new(
  title: "Abonnement mensuel de box beauté",
  description: "Box mensuelle avec des produits de beauté bio",
  price: 29.99,
  link: "https://example.com/box-beaute",
  image_url: "https://example.com/image-box.jpg",
  created_by: alice,
  status: "buying"
)
beaute.recipients = [diane]
beaute.save!

yoga = GiftIdea.new(
  title: "Cours de yoga en ligne (annuel)",
  description: "Abonnement annuel à des cours de yoga en ligne",
  price: 119.99,
  link: "https://example.com/cours-yoga",
  image_url: "https://example.com/image-yoga.jpg",
  created_by: charlie,
  status: "proposed"
)
yoga.recipients = [diane]
yoga.save!

# Pour Admin
jardinage = GiftIdea.new(
  title: "Kit de jardinage intérieur",
  description: "Kit pour faire pousser des herbes aromatiques en intérieur",
  price: 45.00,
  link: "https://example.com/kit-jardinage",
  image_url: "https://example.com/image-jardinage.jpg",
  created_by: diane,
  status: "proposed"
)
jardinage.recipients = [admin]
jardinage.save!

stylo = GiftIdea.new(
  title: "Stylo de luxe personnalisé",
  description: "Stylo haut de gamme avec gravure personnalisée",
  price: 65.00,
  link: "https://example.com/stylo-luxe",
  image_url: "https://example.com/image-stylo.jpg",
  created_by: alice,
  status: "buying"
)
stylo.recipients = [admin]
stylo.save!

# Création de quelques idées de cadeaux avec plusieurs destinataires
puts "Création d'idées de cadeaux avec plusieurs destinataires..."

cadeaux_groupe = GiftIdea.new(
  title: "Jeu de société collaboratif",
  description: "Un jeu de société collaboratif pour soirées entre amis",
  price: 49.99,
  link: "https://example.com/jeu-societe",
  image_url: "https://example.com/image-jeu.jpg",
  created_by: admin,
  status: "proposed"
)
cadeaux_groupe.recipients = [bob, charlie, diane]
cadeaux_groupe.save!

atelier_cuisine = GiftIdea.new(
  title: "Atelier de cuisine en ligne",
  description: "Un atelier de cuisine en ligne pour apprendre à faire des plats gourmets",
  price: 89.99,
  link: "https://example.com/atelier-cuisine",
  image_url: "https://example.com/image-atelier.jpg",
  created_by: bob,
  status: "buying"
)
atelier_cuisine.recipients = [alice, diane]
atelier_cuisine.save!

escape_game = GiftIdea.new(
  title: "Session d'escape game",
  description: "Une session d'escape game pour toute l'équipe",
  price: 120.00,
  link: "https://example.com/escape-game",
  image_url: "https://example.com/image-escape.jpg",
  created_by: alice,
  status: "proposed"
)
escape_game.recipients = [admin, bob, charlie, diane]
escape_game.save!

puts "#{GiftIdea.count} idées de cadeaux créées."
puts "#{GiftRecipient.count} associations gift_recipients créées."

puts "Génération des données terminée avec succès!"
