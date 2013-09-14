class NotesController < ApplicationController
  respond_to :html, :json

  # GET /notes.json
  def index
    respond_with(@notes = Note.all)
  end

  # GET /notes/1.json
  def show
    @note = Note.find(params[:id])
    respond_with @note
  end

  # GET /notes/new.json
  def new
    @note = Note.new
    respond_with @note
  end

  # GET /notes/1/edit
  def edit
    @note = Note.find(params[:id])
    respond_with @note
  end

  # POST /notes.json
  def create
    @note = Note.new(params[:note])

    respond_with(@note) do |format|
      if @note.save
        format.html { redirect_to @note, notice: 'Note was successfully created.' }
        format.json { render json: @note, status: :created, location: @note }
      else
        format.html { render action: "new" }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /notes/1.json
  def update
    @note = Note.find(params[:id])

    respond_with(@note) do |format|
      if @note.update_attributes(params[:note])
        format.html { redirect_to @note, notice: 'Note was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notes/1.json
  def destroy
    @note = Note.find(params[:id])
    @note.destroy
    respond_with(@note) do |format|
      format.html { redirect_to notes_url }
      format.json { head :no_content }
    end
  end
end
