class BazarMailer < ActionMailer::Base 
  
#  if defined?("User")
#    user = User.find_by_id(1)
#    if (!user.nil?)
#      default :from => "Admin Bazar <#{user.email}>"
#    else 
#      default :from => "Admin Bazar <juantomas.garcia@gmail.com>"    
#    end 
#  else 
#    default :from => "Admin Bazar <juantomas.garcia@gmail.com>"    
#  end 
  
  def confirmacion_registro(user)  
    
    @username = user.login
    @userid = user.id
    @url = Cluster.find_by_id(Conf.find_by_nombre('BazarId').valor).url
    @bazar = Conf.find_by_nombre('Titular').valor

    mail(:to => user.email, :subject => "[#{@bazar}] Se ha registrado en el Bazar")  
    
  end
  
  def pruebas
    mail(:from => "no-replay@garumfundatio.org", :to => "juantomas.garcia@gmail.com", :subject => "Pruebas")
  end

  def enviamensaje(de, para, asunto, texto)  
    @de = de
    @para = para
    @asunto = asunto
    @texto = texto
    
    logger.debug("Enviando correo De: #{de} a #{para} -> asunto: #{asunto}")
    
    mail(:from => de, :to => para, :subject => asunto)  
  end

end
