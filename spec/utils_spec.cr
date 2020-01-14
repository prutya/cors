require "./spec_helper"

describe Cors::Utils do
  describe ".normalize_header" do
    it "transforms headers to lowercase and removes spaces" do
      Cors::Utils.normalize_header("  Content-Type ").should eq "content-type"
    end
  end

  describe ".parse_headers" do
    it "splits headers by comma and transforms them to lowercase" do
      Cors::Utils
        .parse_headers("  Accept,Content-Type,  X-Requested-With")
        .should eq ["accept", "content-type", "x-requested-with"]
    end
  end

  describe ".prettify_headers_join" do
    it "capitalizes lowercase headers and joins them with default separator" do
      Cors::Utils
        .prettify_headers_join(["accept", "content-type"])
        .should eq "Accept, Content-Type"
    end

    it "capitalizes lowercase headers and joins them with custom separator" do
      Cors::Utils
        .prettify_headers_join(["accept", "content-type"], ',')
        .should eq "Accept,Content-Type"
    end
  end

  describe ".prettify_header" do
    it "capitalizes lowercase header without hyphens" do
      Cors::Utils.prettify_header("accept").should eq "Accept"
    end

    it "capitalizes lowercase header with hyphens" do
      Cors::Utils.prettify_header("content-type").should eq "Content-Type"
    end
  end
end
