# Configuration pour Active Model Serializers
ActiveModelSerializers.config.adapter = :json

# Transformation des clés en camelCase
ActiveModelSerializers.config.key_transform = :camel_lower

# Pour le scope passé via controller
ActiveModel::Serializer.config.default_includes = '**'
