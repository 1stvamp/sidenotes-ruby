# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Integration: Full generation workflow" do
  it "generates and cleans a complete set of annotations" do
    generator = Sidenotes::Generator.new
    generator.generate_all

    dir = Sidenotes.configuration.output_directory

    # Verify files exist
    yml_files = Dir.glob(File.join(dir, "**", "*.yml"))
    expect(yml_files).not_to be_empty

    # Verify User annotation content
    user_file = yml_files.find { |f| f.end_with?("/user.yml") }
    expect(user_file).not_to be_nil

    content = File.read(user_file)
    yaml_content = content.lines.reject { |l| l.start_with?("#") }.join
    parsed = YAML.safe_load(yaml_content)

    expect(parsed["User"]["metadata"]["table_name"]).to eq("users")
    expect(parsed["User"]["columns"]).to be_an(Array)
    expect(parsed["User"]["indexes"]).to be_an(Array)
    expect(parsed["User"]["associations"]).to be_an(Array)

    # Clean up
    generator.clean
    expect(Dir.glob(File.join(dir, "**", "*.yml"))).to be_empty
  end

  it "generates JSON format when configured" do
    Sidenotes.configure { |c| c.format = :json }

    generator = Sidenotes::Generator.new
    generator.generate_all

    dir = Sidenotes.configuration.output_directory
    json_files = Dir.glob(File.join(dir, "**", "*.json"))
    expect(json_files).not_to be_empty

    user_file = json_files.find { |f| f.end_with?("/user.json") }
    parsed = JSON.parse(File.read(user_file))
    expect(parsed["User"]["metadata"]["table_name"]).to eq("users")
  end

  it "generates annotations for polymorphic models" do
    generator = Sidenotes::Generator.new
    generator.generate_for(Comment)

    dir = Sidenotes.configuration.output_directory
    comment_file = File.join(dir, "comment.yml")
    expect(File.exist?(comment_file)).to be true

    content = File.read(comment_file)
    yaml_content = content.lines.reject { |l| l.start_with?("#") }.join
    parsed = YAML.safe_load(yaml_content)

    associations = parsed["Comment"]["associations"]
    commentable = associations.find { |a| a["name"] == "commentable" }
    expect(commentable["polymorphic"]).to be true
  end

  it "generates annotations for STI subclasses" do
    generator = Sidenotes::Generator.new
    generator.generate_for(AdminUser)

    dir = Sidenotes.configuration.output_directory
    admin_file = File.join(dir, "admin_user.yml")
    expect(File.exist?(admin_file)).to be true
  end

  it "handles custom output directory" do
    Sidenotes.configure { |c| c.output_directory = "schema_metadata" }

    generator = Sidenotes::Generator.new
    generator.generate_for(User)

    expect(File.exist?("schema_metadata/user.yml")).to be true
  end

  it "excludes models matching patterns" do
    Sidenotes.configure do |c|
      c.exclude_patterns = [/^Admin/, "ModeratorUser"]
    end

    generator = Sidenotes::Generator.new
    generator.generate_all

    expect(generator.models_generated).not_to include("AdminUser")
    expect(generator.models_generated).not_to include("ModeratorUser")
    expect(generator.models_generated).to include("User")
  end

  it "only generates selected sections" do
    Sidenotes.configure { |c| c.sections = %i[columns metadata] }

    generator = Sidenotes::Generator.new
    generator.generate_for(User)

    dir = Sidenotes.configuration.output_directory
    content = File.read(File.join(dir, "user.yml"))
    yaml_content = content.lines.reject { |l| l.start_with?("#") }.join
    parsed = YAML.safe_load(yaml_content)

    expect(parsed["User"]).to have_key("columns")
    expect(parsed["User"]).to have_key("metadata")
    expect(parsed["User"]).not_to have_key("indexes")
    expect(parsed["User"]).not_to have_key("associations")
  end
end
