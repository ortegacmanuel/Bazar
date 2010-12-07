class MensajesController < ApplicationController
  layout "bazar"
  def index
    puts "-------> parametros: ("+params.inspect+")"
    if (!params[:tipo].nil?)
      if (params[:tipo] == 'N')
        puts "Buscando notificaciones"
        @mensajes = Mensaje.notificacionestotal(current_user.id).order('fecha desc').paginate(:page => params[:page], :per_page => 15)
      else 
        puts "Buscando Mensajes"
        @mensajes = Mensaje.mensajestotal(current_user.id).order('fecha desc').paginate(:page => params[:page], :per_page => 15)      
      end 
    else 
      puts "No esta definido tipo"
      @mensajes = Mensaje.where('para = ? and tipo = "N"',[current_user.id]).order('fecha desc').paginate(:page => params[:page], :per_page => 15)
    end 
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @mensajes }
    end

  end

  def editanotificacion
    
  end
  
  def leido 
    puts "leido #{params[:id]}"
    puts "Usuario actual #{current_user.id}"
    @mensaje = Mensaje.find(params[:id])
    if(@mensaje.para == current_user.id)
      @mensaje.leido = DateTime.now 
      @mensaje.save
    else 
      puts "Este mensaje #{@mensaje.para} No era del usuario #{current_user.id}"
    end 
  end 
  
  def show
    @mensaje = Mensaje.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @mensaje }
    end
  end

  def new
    @mensaje = Mensaje.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @mensaje }
    end
  end

  def edit
    @mensaje = Mensaje.find(params[:id])
  end

  def create
    @mensaje = Mensaje.new(params[:mensaje])

    respond_to do |format|
      if @mensaje.save
        format.html { redirect_to(@mensaje, :notice => 'Mensaje was successfully created.') }
        format.xml  { render :xml => @mensaje, :status => :created, :location => @mensaje }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @mensaje.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /mensajes/1
  # PUT /mensajes/1.xml
  def update
    
    @mensaje = Mensaje.find(params[:id])
    @mensaje2 = Mensaje.new(params[:mensaje])
    @mensaje2.fecha = DateTime.now
    @mensaje2.de = @mensaje.para
    @mensaje2.para = @mensaje.de 
    @mensaje2.tipo = @mensaje.tipo
    @mensaje2.leido = nil 
    @mensaje2.borrado = nil
    
    respond_to do |format|
      if @mensaje2.save
        format.html { redirect_to(@mensaje, :notice => 'Mensaje ha sido enviado.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @mensaje.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /mensajes/1
  # DELETE /mensajes/1.xml
  def destroy
    @mensaje = Mensaje.find(params[:id])
    @mensaje.destroy

    respond_to do |format|
      format.html { redirect_to(mensajes_url) }
      format.xml  { head :ok }
    end
  end
end