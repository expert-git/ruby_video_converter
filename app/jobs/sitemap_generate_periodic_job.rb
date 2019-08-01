class SitemapGeneratePeriodicJob < ApplicationJob
  def perform
    setup

    generate

    ping_search_engines
  end

  private

  def setup
    # require inline so it's not loaded in web environment
    require "sitemap_generator"

    require "aws-sdk"
    SitemapGenerator::Sitemap.adapter = SitemapGenerator::AwsSdkAdapter.new(Rails.application.credentials[Rails.env.to_sym][:SITEMAP_S3_BUCKET])

    SitemapGenerator.verbose = true
  end

  def generate
    SitemapGenerator::Interpreter.run
  end

  def ping_search_engines
    SitemapGenerator::Sitemap.ping_search_engines if Rails.application.credentials[Rails.env.to_sym][:SITEMAP_PING].present?
  end
end
