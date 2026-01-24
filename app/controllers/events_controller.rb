class EventsController < ApplicationController
  before_action :authenticate_user!, except: %i[ index ]
  before_action :set_event, only: %i[ show edit update destroy ]

  def fetch_ogp
    url = params[:url]
    return render json: { error: "URL is required" }, status: :bad_request if url.blank?

    begin
      page = MetaInspector.new(url)
      render json: { title: page.best_title, image: page.images.best }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # GET /events or /events.json
  def index
    if logged_in?
      @events = current_user.events.order(end_date: :asc)
      if params[:q].present?
        query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
        @events = @events.where("title LIKE ? OR description LIKE ? OR location LIKE ?", query, query, query)
      end
    else
      @events = []
    end
  end

  def calendar
    @events = current_user.events
  end

  # GET /events/1 or /events/1.json
  def show
  end

  # GET /events/new
  def new
    @event = current_user.events.build
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events or /events.json
  def create
    @event = current_user.events.build(event_params)

    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: t("flash.created", model: Event.model_name.human) }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to @event, notice: t("flash.updated", model: Event.model_name.human), status: :see_other }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    @event.destroy!

    respond_to do |format|
      format.html { redirect_to events_path, notice: t("flash.destroyed", model: Event.model_name.human), status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.expect(event: [ :title, :url, :description, :image_url, :start_date, :end_date, :location, :memo, :status, :scheduled_date ])
    end
end
