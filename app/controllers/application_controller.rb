class ApplicationController < ActionController::Base

  protect_from_forgery

  before_filter :set_locale
  before_filter :set_tema
  
  helper_method :current_user_session, :current_user, :current_user_is_admin, :current_user_is_dinamizador, 
            :current_user_is_invitado, :BZ_param, :dohttp, :helper_rating_show2, :helper_formatea, :datos_empresa_remota,
            :logo_helper, :logo_grande_helper, :datos_oferta_remota, :helper_rating_show_ng, :helper_rating_show_detail_ng,
            :set_theme, :user_theme_color, :user_news, :user_favoritos, :user_correos
  
  helper :all
  
  require "net/http"
  require "uri"

  def set_tema
    
    # TODO: deberíamos mirar si el usuario ha definido un tema
    # y crear el campo en las preferencias de usuario
    
    # primero miramos si existe una configuración global 
    
    conf = Conf.find_by_nombre("Theme")
    if !conf.nil? 
      tema = conf.valor
    else 
      conf = Conf.new 
      conf.nombre = "Theme"
      tema = "bazar"
      conf.valor = tema
      conf.grupo_id = 1
      conf.tipo = "string"
      conf.desc = "Theme por defecto"
      conf.save 
    end 
    
    logger.debug "Theme ---------> "+tema+"<-----"
    theme tema
    
  end

  def set_locale
      # I18n.locale = params[:locale] if params.include?('locale')
      # || ((lang = request.env['HTTP_ACCEPT_LANGUAGE']) && lang[/^[a-z]{2}/])
      
      # prioridades del lenguaje
      # 1 si viene un locale definiddo por url 
      # 2 lo que haya determinado el usuario 
      # 3 el lenguaje por defecto del navegador
      # 4 lenguaje por defecto del sitio 
      # 5 Inglés 
      
      # 1 locale forzado
      
      if params.include?('locale') 
        I18n.locale = params[:locale]
        logger.debug "I18N -------> 1 locale forzado"+params[:locale]
        return
      end 
        
      # 2 por que lo fuerza el usuario
      
      if !current_user.nil?
        if !current_user.idioma.nil?
          I18n.locale = current_user.idioma
          logger.debug "I18N -------> 2 por que lo fuerza el usuario"+current_user.idioma
          return 
        end
      end 
      
      # 3 el lenguaje por defecto del navegador si es que lo soporta bazar
      
      if ((lang = request.env['HTTP_ACCEPT_LANGUAGE']) && lang[/^[a-z]{2}/])
        logger.debug "HTTP_ACCEPT_LANGUAGE ----->"+lang
        case lang[0,2]
        when 'es', 'en', 'eo'
          I18n.locale = lang[0,2]
          logger.debug "I18N -------> 3 el lenguaje por defecto del navegador si es que lo soporta bazaro"+lang[0,2]
          return
        else 
          logger.debug "WARNING: No soportamos esta lengua ----->"+lang  
        end 
      end
      
      # 4 lenguaje por defecto del sitio 
      
      conf = conf = Conf.find_by_nombre("Lang")
      if !conf.nil? 
        lang = conf.valor
      else 
        conf = Conf.new 
        conf.nombre = "Lang"
        lang = "en"
        conf.valor = lang
        conf.grupo_id = 1
        conf.tipo = "string"
        conf.desc = "Idioma del Bazar"
        conf.save 
      end
      
      I18n.locale = lang
      logger.debug "I18N ------->  4 lenguaje por defecto del sitio "+lang
      
  end

  def BZ_param(clave)
    conf = Rails.cache.fetch("BZ#{clave}", :expires_in => 15.minutes) do
      conf = Conf.find_by_nombre(clave)
    end
    
    if !conf.nil?
      return conf.valor
    else
      return "Valor sin definir" 
    end 
  end
    
    
  def user_theme_color 
    
    if current_user.nil?
      return "01"
    else 
      if !current_user.temacolor.nil?
        return current_user.temacolor
      else
        current_user.temacolor = "01"
        current_user.save
        return "01" 
      end
    end
    
  end 

  def user_news 
    
    if current_user.nil?
      return "S"
    else 
      if !current_user.news.nil?
        return current_user.news
      else
        current_user.temacolor = "S"
        current_user.save
        return "S" 
      end
    end
    
  end 

  def user_favoritos 
    
    if current_user.nil?
      return "S"
    else 
      if !current_user.favoritos.nil?
        return current_user.favoritos
      else
        current_user.favoritos = "S"
        current_user.save
        return "S" 
      end
    end
    
  end 

  def user_correos 
    
    if current_user.nil?
      return "S"
    else 
      if !current_user.correos.nil?
        return current_user.correos
      else
        current_user.correos = "S"
        current_user.save
        return "S" 
      end
    end
    
  end 

  
  def helper_rating_show2(bazar, empresa)
     
     if (bazar.to_i == BZ_param("BazarId").to_i)
       
       empre = Bazarcms::Empresa.find_by_id(empresa)
       
       if !empre.nil? 
         valor = empre.rating
         nombre = empre.nombre.gsub(' ','_')
       else 
         valor = 0
         nombre = "Sin rating"
       end 
       
       url = "/bazarcms/ficharating/#{empresa}?bazar_id=#{bazar}"
       
     else 
       
       # si no es de este bazar le pedimos al otro bazar que nos 
       # de su rating. 
       # TODO JT esto habría que cachearlo para optimizar las comunicaciones
       
       res = Rails.cache.fetch("emp-json-#{bazar}-#{empresa}", :expires_in => 8.hours) do
         logger.debug "----> no estaba cacheado emp-json-#{bazar}-#{empresa}"
         res = dohttpget(bazar, "/api/infoempresa.json/#{empresa}")
       end
       
       logger.debug "json empresa ------->"+res.inspect
       if (res.length > 1)
         begin
           empre = JSON.parse(res)
         rescue 
           
           logger.debug "OJO ---> No es parseable este json: #{res} de emp-json-#{bazar}-#{empresa}"
           valor = 0
           expire_fragment "emp-json-#{bazar}-#{empresa}"
          else
            logger.debug "json empresa2 ------->"+empre.inspect

            if (!empre['rating'].nil?)
              logger.debug "json empresa3 ------->#{empre['rating']}"
              valor = empre['rating']
            else 
              valor = 0
            end 
          end
       else 
         valor = 0
       end 
       
       url = "/bazarcms/ficharating/#{empresa}?bazar_id=#{bazar}"

     end
     
     val = "#{valor}".split('.')[0]
     str = "<div><a href='#{url}' title='Ver el Rating de esta empresa'>" 
     
     for ii in ['1', '2', '3', '4', '5'] 
     
       if (ii > val) 
         str += "<img src='/images/addfav.png'>"
       else 
         str += "<img src='/images/rating.png'>"
       end 
       
     end 
     
     str += "</a></div>"
     str 
   end

   def helper_rating_show_ng(bazar, empresa)

      if (bazar.to_i == BZ_param("BazarId").to_i)

        empre = Bazarcms::Empresa.find_by_id(empresa)

        if !empre.nil? 
          valor = empre.rating
          nombre = empre.nombre.gsub(' ','_')
        else 
          valor = 0
          nombre = "Sin rating"
        end 

        url = "/bazarcms/ficharating/#{empresa}?bazar_id=#{bazar}"

      else 

        # si no es de este bazar le pedimos al otro bazar que nos 
        # de su rating. 
        # TODO JT esto habría que cachearlo para optimizar las comunicaciones

        res = Rails.cache.fetch("emp-json-#{bazar}-#{empresa}", :expires_in => 8.hours) do
          logger.debug "----> no estaba cacheado emp-json-#{bazar}-#{empresa}"
          res = dohttpget(bazar, "/api/infoempresa.json/#{empresa}")
        end

        logger.debug "json empresa ------->"+res.inspect
        if (res.length > 1)
          begin
            empre = JSON.parse(res)
          rescue 

            logger.debug "OJO ---> No es parseable este json: #{res} de emp-json-#{bazar}-#{empresa}"
            valor = 0
            expire_fragment "emp-json-#{bazar}-#{empresa}"
           else
             logger.debug "json empresa2 ------->"+empre.inspect

             if (!empre['rating'].nil?)
               logger.debug "json empresa3 ------->#{empre['rating']}"
               valor = empre['rating']
             else 
               valor = 0
             end 
           end
        else 
          valor = 0
        end 

        url = "/bazarcms/ficharating/#{empresa}?bazar_id=#{bazar}"

      end

      val = "#{valor}".split('.')[0]
      str = ""

      for ii in ['1', '2', '3', '4', '5'] 

        if (ii > val) 
          str += "<img class='fichaempresa-rating-img' src='"+current_theme_image_path('estrellawhite40.png')+"'>"
        else 
          str += "<img class='fichaempresa-rating-img' src='"+current_theme_image_path('estrellawhite.png')+"'>"
        end 

      end 

      str += ""
      str 
    end

    def helper_rating_show_detail_ng(bazar, empresa)

      logger.debug "Detalle de rating para bazar #{bazar} empresa #{empresa}"
       if (bazar.to_i == BZ_param("BazarId").to_i)

         ratings = Bazarcms::Rating.where("1 = 1")

         str = ""
         
         valores = {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}
         total = 0 
         
         for rating in ratings
           
           logger.debug "rating: "+rating.inspect
           tipo = ""
           tipo = "ori" if (rating.ori_bazar_id == bazar.to_i && rating.ori_empresa_id == empresa.to_i)
           tipo = "des" if (rating.des_bazar_id == bazar.to_i && rating.des_empresa_id == empresa.to_i)
              
           if tipo == ""
             logger.debug "Me lo salto"
             next
           end 
             
           if (tipo == "ori")
              valor = rating.des_valor
              logger.debug "Me lo salto solo sacamos los que le han votado"
              next 
           else 
              rat = Bazarcms::Rating.where("ori_bazar_id = ? and ori_empresa_id = ? and des_bazar_id = ? and des_empresa_id = ?",
                                            bazar, empresa, rating.ori_bazar_id, rating.ori_empresa_id).limit(1)
              if rat == []
                logger.debug "Me salto esta valoración por que no ha sido correspondida"
                next 
              end 
                                            
              valor = rating.ori_valor 
           end 
           
           if valor.nil?
              logger.debug "No tiene valor!!"
              next
           else 
              valores["#{valor}".split('.')[0]] += 1
           end 
           total += 1 
           
           logger.debug "Entra: id #{rating.id} valor #{valor}"
           
         end
         
         str += "<div class='fichaempresa-rating-show-detail'>"
         str += " <div class='fichaempresa-rating-show-detail-text'> #{total} "+t(:text_empresas_han_votado)+"</div>"
         str += "</div>" 
         
         for valor in valores 
           if total > 0
             per = valor[1] * 100 / total 
           else 
             per = 0 
           end

           str += "<div class='fichaempresa-rating-show-detail2' style='background-size: #{per}\% auto;' "
           # str += "onclick='document.location.href=\"/home/ficharating/#{bazar}/#{empresa}/#{valor[0]}\";' >"
           str += "onclick=\"$('#ficharating').attr('href', '/home/ficharating/#{bazar}/#{empresa}/#{valor[0]}').trigger('click');\" >"
           str += "<div class='fichaempresa-rating-show-detail-text2'>"+t(:text_puntuar_con)

           val = "#{valor}".split('.')[0]
           for ii in ['1', '2', '3', '4', '5'] 

             if (ii <=  val) 
               str += "<img  src='"+current_theme_image_path('estrellawhite.png')+"' style='margin-left: 5px;'>"
#             else 
#               str += "<img src='"+current_theme_image_path('estrellawhite40.png')+"'>"
             end 

           end 
           str += "</div>"+"</div>"
         end 
         
       else 

         # si no es de este bazar le pedimos al otro bazar que nos 
         # de su rating. 
         # TODO JT esto habría que cachearlo para optimizar las comunicaciones

         res = Rails.cache.fetch("emp-json-#{bazar}-#{empresa}", :expires_in => 8.hours) do
           logger.debug "----> no estaba cacheado emp-json-#{bazar}-#{empresa}"
           res = dohttpget(bazar, "/api/infoempresa.json/#{empresa}")
         end

         logger.debug "json empresa ------->"+res.inspect
         if (res.length > 1)
           begin
             empre = JSON.parse(res)
           rescue 

             logger.debug "OJO ---> No es parseable este json: #{res} de emp-json-#{bazar}-#{empresa}"
             valor = 0
             expire_fragment "emp-json-#{bazar}-#{empresa}"
            else
              logger.debug "json empresa2 ------->"+empre.inspect

              if (!empre['rating'].nil?)
                logger.debug "json empresa3 ------->#{empre['rating']}"
                valor = empre['rating']
              else 
                valor = 0
              end 
            end
         else 
           valor = 0
         end 

         url = "/bazarcms/ficharating/#{empresa}?bazar_id=#{bazar}"

       end


       str += ""
       str 
     end

   def logo_grande_helper(bazar, empresa)

      if (bazar.to_i == BZ_param("BazarId").to_i)

        empre = Bazarcms::Empresa.find_by_id(empresa)

        if !empre.nil? 
          url = empre.logo.url(:s223)
        else 
          url = nil
        end 

      else 

        # si no es de este bazar le pedimos al otro bazar que nos de su logo

        res = Rails.cache.fetch("emp-json-#{bazar}-#{empresa}", :expires_in => 8.hours) do
          logger.debug "----> no estaba cacheado emp-json-#{bazar}-#{empresa}"
          res = dohttpget(bazar, "/api/infoempresa.json/#{empresa}")
        end

        logger.debug "json empresa ------->"+res.inspect
        if (res.length > 1)
          begin
            empre = JSON.parse(res)
          rescue 

            logger.debug "OJO ---> No es parseable este json: #{res} de emp-json-#{bazar}-#{empresa}"
            url = nil
            expire_fragment "emp-json-#{bazar}-#{empresa}"
           else
             logger.debug "json empresa2 ------->"+empre.inspect

             if (!empre['logo'].nil?)
               logger.debug "json empresa3 ------->#{empre['logo']}"
               cluster = Cluster.find(bazar)
               url = "#{cluster.url}/"+empre['logo']
             else 
               url = nil
             end 
           end
        else 
          url = nil
        end 

      end
      
      url
    end

    def logo_helper(bazar, empresa)

       if (bazar.to_i == BZ_param("BazarId").to_i)

         empre = Bazarcms::Empresa.find_by_id(empresa)

         if !empre.nil? 
           url = empre.logo.url(:thumb)
         else 
           url = nil
         end 

       else 

         # si no es de este bazar le pedimos al otro bazar que nos de su logo

         res = Rails.cache.fetch("emp-json-#{bazar}-#{empresa}", :expires_in => 8.hours) do
           logger.debug "----> no estaba cacheado emp-json-#{bazar}-#{empresa}"
           res = dohttpget(bazar, "/api/infoempresa.json/#{empresa}")
         end

         logger.debug "json empresa ------->"+res.inspect
         if (res.length > 1)
           begin
             empre = JSON.parse(res)
           rescue 

             logger.debug "OJO ---> No es parseable este json: #{res} de emp-json-#{bazar}-#{empresa}"
             url = nil
             expire_fragment "emp-json-#{bazar}-#{empresa}"
            else
              logger.debug "json empresa2 ------->"+empre.inspect

              if (!empre['logo'].nil?)
                logger.debug "json empresa3 ------->#{empre['logo']}"
                cluster = Cluster.find(bazar)
                url = "#{cluster.url}/"+empre['logo']
              else 
                url = nil
              end 
            end
         else 
           url = nil
         end 

       end


       url
     end


  
   def helper_formatea(texto)

     if !texto.nil?
       texto.gsub(/\n/,'<br/>').html_safe
     else 
       ""
     end
     
   end
   
   def datos_empresa_remota (bazar, empresa)
                 
     res = Rails.cache.fetch("emp-json-#{bazar}-#{empresa}", :expires_in => 8.hours) do
       logger.debug "----> no estaba cacheado emp-json-#{bazar}-#{empresa}"
       res = dohttpget(bazar, "/api/infoempresa.json/#{empresa}")
     end
       
     if (res.length > 1)
       begin
         empre = JSON.parse(res)
       rescue 
         
         logger.debug "OJO ---> No es parseable este json: #{res} de emp-json-#{bazar}-#{empresa}"
         empre = nil
         expire_fragment "emp-json-#{bazar}-#{empresa}"
       else
          logger.debug "json empresa2 ------->"+empre.inspect
        end
     else 
       empre = nil
     end 
     
     empre
      
   end 
   
   def datos_oferta_remota (bazar, oferta)
                 
     res = Rails.cache.fetch("ofe-json-#{bazar}-#{oferta}", :expires_in => 8.hours) do
       logger.debug "----> no estaba cacheado ofe-json-#{bazar}-#{oferta}"
       res = dohttpget(bazar, "/api/infooferta.json/#{oferta}")
     end
       
     if (res.length > 1)
       begin
         ofe = JSON.parse(res)
       rescue 
         
         logger.debug "OJO ---> No es parseable este json: #{res} de ofe-json-#{bazar}-#{oferta}"
         ofe = nil
         expire_fragment "ofe-json-#{bazar}-#{oferta}"
       else
          logger.debug "json empresa2 ------->"+ofe.inspect
        end
     else 
       ofe = nil
     end 
     
     ofe
      
   end
  private
    def current_user_session
      logger.debug "ApplicationController::current_user_session"
      logger.debug "#{@current_user_session.inspect}"
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      logger.debug "ApplicationController::current_user"
      # logger.debug "preguntando por quien es el current user: #{@current_user.inspect}"
      return @current_user if defined?(@current_user)
      logger.debug "No parece que este definido resetamos @current_user"
      @current_user = current_user_session && current_user_session.user
      logger.debug "ahora es current user: #{@current_user.inspect}"

      return @current_user if defined?(@current_user)
    end

    def current_user_is_admin
      logger.debug "ApplicationController::current_user_is_Admin"
      if (!current_user.nil?)
        current_user.roles.select{|i| 
          if (i.rol == 'admin') 
            return true 
          end
          }
      end   
      return false
    end

    def current_user_is_dinamizador
      logger.debug "ApplicationController::current_user_is_dinamizador"
      if (!current_user.nil?)
        current_user.roles.select{|i| 
          if (i.rol == 'dinamizador') 
            return true 
          end
          }
      end   
      return false
    end

    def current_user_is_invitado
      logger.debug "ApplicationController::current_user_is_invitado"
      if (!current_user.nil?)
        current_user.roles.select{|i| 
          if (i.rol == 'invitado') 
            return true 
          end
          }
      end   
      return false
    end

    def require_user
      logger.debug "ApplicationController::require_user"
      unless current_user
        store_location
        flash[:notice] = "Debes entrar en el sistema para poder acceder a esta página"
        redirect_to '/?action=login'
        return false
      end
    end

    def require_no_user
      logger.debug "ApplicationController::require_no_user"
      logger.debug ""
      if current_user
        store_location
        flash[:notice] = "Debes entrar en el sistema para poder acceder a esta página"
        redirect_to "/home"
        return false
      end
    end

    def store_location
      session[:return_to] = request.request_uri
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    
    def dohttppost (bazar, pet, body)
      
      logger.debug "dohttp: bazar #{bazar}: Enviando #{pet}"
    
      cluster = Cluster.find(bazar)
      uri = URI.parse("#{cluster.url}/#{pet}")
      
      post_body = []
      post_body << body 
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = http.read_timeout = 10

      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = post_body.join
      request["Content-Type"] = "text/plain"

      begin 

        res =  Net::HTTP.new(uri.host, uri.port).start {|http| http.request(request) }
        case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          return res.body
        else
          logger.debug "dohttp: ERROR en la petición a #{uri}---------->"+res.error!
          return ""
        end

      rescue Exception => e
        logger.debug "dohttp: Exception leyendo #{cluster.url} Got #{e.class}: #{e}"
        return ""        
      end

    end 

    def dohttpget (bazar, pet)

      logger.debug "dohttp: bazar #{bazar}: Enviando #{pet}"
      
      hydra = Typhoeus::Hydra.new

      cluster = Cluster.find(bazar)
      uri = "#{cluster.url}/#{pet}"

      r = Typhoeus::Request.new(uri, :timeout => 10000)
      
      r.on_complete do |response|
         logger.debug "dohttpget -------------> "+response.inspect
         case response.curl_return_code
         when 0
           if response.code == 404 
             return "404"
           else 
             return response.body
           end 
         else
           logger.debug "ERROR en la petición ---------->"+response.inspect
           return ""
         end
         
      end
      
      hydra.queue r
      hydra.run

    end 
        
end

