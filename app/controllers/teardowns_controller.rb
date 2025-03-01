# frozen_string_literal: true

class TeardownsController < ApplicationController
  before_action :authenticate_user!, except: %[show]
  before_action :set_metadata, only: %i[show destroy]

  def index
    @title = t('.title')
    @metadata = Metadatum.page(params.fetch(:page, 1))
                         .per(params.fetch(:per_page, 50))
                         .order(id: :desc)
  end

  def show
    authorize @metadata
    @title = t('.title', name: @metadata.name,
                release_version: @metadata.release_version,
                build_version: @metadata.build_version)
  end

  def new
    @title = t('.title')
    @metadata = Metadatum.new
    authorize @metadata
  end

  def create
    @title = t('.title')
    parse_app
  rescue AppInfo::NotFoundError, ActiveRecord::RecordNotFound => e
    flash[:error] = t('teardowns.messages.errors.not_found_file', message: e.message)
    render :new, status: :unprocessable_entity
  rescue ActionController::RoutingError => e
    flash[:error] = e.message
    render :new, status: :unprocessable_entity
  rescue AppInfo::UnkownFileTypeError
    flash[:error] = t('teardowns.messages.errors.failed_detect_file_type')
    render :new, status: :unprocessable_entity
  rescue AppInfo::UnkownFileTypeError
    flash[:error] = t('teardowns.messages.errors.not_support_file_type')
    render :new, status: :unprocessable_entity
  rescue NoMethodError => e
    logger.error "Teardown error: #{e}"
    Sentry.capture_exception e
    flash[:error] = t('teardowns.messages.errors.failed_get_metadata')
    render :new, status: :unprocessable_entity
  rescue => e
    logger.error "Teardown error: #{e}"
    logger.error "Throws backtraces are: #{e.backtrace.join("\n")}"
    Sentry.capture_exception e
    flash[:error] = t('teardowns.messages.errors.unknown_parse', class: e.class, message: e.message)
    render :new, status: :unprocessable_entity
  end

  def destroy
    authorize @metadata
    @metadata.destroy

    redirect_to teardowns_path, notice: t('activerecord.success.destroy', key: "#{t('teardowns.title')}")
  end

  private

  def set_metadata
    @metadata = Metadatum.find(params[:id])
  end

  def parse_app
    unless file = params[:file]
      raise ActionController::RoutingError, t('teardowns.messages.errors.choose_supported_file_type')
    end

    metadata = TeardownService.new(file).call
    metadata.update_attribute(:user_id, current_user&.id) if current_user.present?

    redirect_to teardown_path(metadata)
  end
end
