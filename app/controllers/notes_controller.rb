class NotesController < ApplicationController
  respond_to :html, :json

  # GET /notes.json
  def index
    @notes = Note.where("trashed = false").order("depth").order("rank")
    respond_with(@notes)
  end

  # GET /notes/1.json
  def show
    @note = Note.find(params[:id])
    respond_with @note
  end

  # POST /notes.json
  def create
    @note = Note.new(params[:note])
    if @note.save
      render json: @note, status: :created, location: @note
    else
      render json: @note.errors, status: :unprocessable_entity
    end
    # respond_with(@note) do |format|
    #   if @note.save
    #     format.html { redirect_to @note, notice: 'Note was successfully created.' }
    #     format.json { render json: @note, status: :created, location: @note }
    #   else
    #     format.html { render action: "new" }
    #     format.json { render json: @note.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # PUT /notes/1.json
  def update
    @note = Note.find(params[:id])
    if @note.update_attributes(params[:note])
      head :no_content
    else
      render json: @note.errors, status: :unprocessable_entity
    end
  end

  # DELETE /notes/1.json
  def destroy
    @note = Note.find(params[:id])
		if @note.parent_id == 'root'
			Note.update(@note.id, :trashed => true)
		else
			@note.destroy
		end
    respond_with(@note) do |format|
      format.html { redirect_to notes_url }
      format.json { head :no_content }
    end
  end

  def search
    @notes = Note.where("trashed = false").search(params[:query])
    respond_with(@notes) do |format|
      format.html { @notes }
      # Even though the request from the search form is a JavaScript request
      # we will still send the response as json because that is what Backbone
      # needs to produce the active tree from the search results
      format.js { render json: @notes }
    end
  end

end

