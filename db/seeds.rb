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
GiftIdea.create!(
  title: "Livre de cuisine végétarienne",
  description: "Un livre avec des recettes végétariennes du monde entier",
  price: 25.99,
  link: "https://example.com/livre-cuisine",
  image_url: "https://example.com/image-livre.jpg",
  for_user: alice,
  created_by: bob,
  status: "proposed"
)

GiftIdea.create!(
  title: "Coffret de thés bio",
  description: "Assortiment de thés biologiques de différentes saveurs",
  price: 39.99,
  link: "https://example.com/coffret-thes",
  image_url: "https://example.com/image-the.jpg",
  for_user: alice,
  created_by: charlie,
  status: "buying"
)

# Pour Bob
GiftIdea.create!(
  title: "Set de bières artisanales",
  description: "Ensemble de 6 bières artisanales de différentes brasseries",
  price: 32.50,
  link: "https://example.com/bieres-artisanales",
  image_url: "https://example.com/image-bieres.jpg",
  for_user: bob,
  created_by: alice,
  status: "proposed"
)

GiftIdea.create!(
  title: "Enceinte Bluetooth portable",
  description: "Enceinte portable avec une autonomie de 20 heures",
  price: 79.99,
  link: "https://example.com/enceinte-bluetooth",
  image_url: "https://example.com/image-enceinte.jpg",
  for_user: bob,
  created_by: diane,
  status: "buying"
)

# Pour Charlie
GiftIdea.create!(
  title: "Casque audio sans fil",
  description: "Casque avec réduction de bruit active",
  price: 149.99,
  link: "https://example.com/casque-audio",
  image_url: "https://example.com/image-casque.jpg",
  for_user: charlie,
  created_by: bob,
  status: "proposed"
)

GiftIdea.create!(
  title: "Set de dégustation de whiskys",
  description: "Coffret avec 4 whiskys du monde et verres de dégustation",
  price: 89.99,
  link: "https://example.com/whisky-set",
  image_url: "https://example.com/image-whisky.jpg",
  for_user: charlie,
  created_by: admin,
  status: "bought"
)

# Pour Diane
GiftIdea.create!(
  title: "Abonnement mensuel de box beauté",
  description: "Box mensuelle avec des produits de beauté bio",
  price: 29.99,
  link: "https://example.com/box-beaute",
  image_url: "https://example.com/image-box.jpg",
  for_user: diane,
  created_by: alice,
  status: "buying"
)

GiftIdea.create!(
  title: "Cours de yoga en ligne (annuel)",
  description: "Abonnement annuel à des cours de yoga en ligne",
  price: 119.99,
  link: "https://example.com/cours-yoga",
  image_url: "https://example.com/image-yoga.jpg",
  for_user: diane,
  created_by: charlie,
  status: "proposed"
)

# Pour Admin
GiftIdea.create!(
  title: "Kit de jardinage intérieur",
  description: "Kit pour faire pousser des herbes aromatiques en intérieur",
  price: 45.00,
  link: "https://example.com/kit-jardinage",
  image_url: "https://example.com/image-jardinage.jpg",
  for_user: admin,
  created_by: diane,
  status: "proposed"
)

GiftIdea.create!(
  title: "Stylo de luxe personnalisé",
  description: "Stylo haut de gamme avec gravure personnalisée",
  price: 65.00,
  link: "https://example.com/stylo-luxe",
  image_url: "https://example.com/image-stylo.jpg",
  for_user: admin,
  created_by: alice,
  status: "buying"
)
puts "#{GiftIdea.count} idées de cadeaux créées."

puts "Génération des données terminée avec succès!"
