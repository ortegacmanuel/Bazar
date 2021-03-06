#!/bin/sh


RAILS_ENV=production
export RAILS_ENV

echo "Instalación de Bazar. La instalación tardará varios minutos." 

cp /dev/null  install.log

echo "Compilando las dependencias en el directorio vendor" 

mkdir -p log 
touch log/acts_as_ferret.log
chmod -R 0777 log 

mkdir -p tmp 
chmod -R 0777 tmp 

bundle install --path vendor 
bundle exec aaf_install

rails generate bazarcms -f  


echo "Haciendo el setup de bazar" 

echo "Creando Directorio" 
rake bazar:mkdir_dirs 

echo "Permisos Directorio" 
rake bazar:setup_dirs 

echo "Creando usuarios en la BD" 
rake bazar:create_users 

echo "Instalando jquery" 
rails generate jquery:install -f

echo "Instalando friendly_id" 
rails generate friendly_id

echo "Creando las tablas de la base de datos" 
rake db:migrate

# rake bazar:db_init
rake db:data:load_dir dir=dbinit 

rake friendly_id:redo_slugs MODEL=Cluster
rake friendly_id:redo_slugs MODEL=Paises
rake friendly_id:redo_slugs MODEL=Ciudad
rake friendly_id:redo_slugs MODEL=Bazarcms::Empresa
rake friendly_id:redo_slugs MODEL=Bazarcms::Oferta
rake friendly_id:redo_slugs MODEL=Bazarcms::Perfil

echo "Actualizando la información del resto de los bazares" 
rake bazar:actualiza
rake sitemap:refresh

