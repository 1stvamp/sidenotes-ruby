# frozen_string_literal: true

require "spec_helper"

RSpec.describe Sidenotes::ModelInspector do
  describe "#inspectable?" do
    it "returns true for a model with a table" do
      inspector = described_class.new(User)
      expect(inspector.inspectable?).to be true
    end

    it "returns false for abstract models" do
      inspector = described_class.new(ApplicationRecord)
      expect(inspector.inspectable?).to be false
    end
  end

  describe "#inspect_model" do
    context "with User model" do
      subject(:data) { described_class.new(User).inspect_model }

      it "returns a hash" do
        expect(data).to be_a(Hash)
      end

      it "includes metadata" do
        expect(data["metadata"]).to include(
          "table_name" => "users",
          "primary_key" => "id"
        )
      end

      it "includes enum definitions in metadata" do
        expect(data["metadata"]["enums"]).to have_key("role")
      end

      it "includes columns" do
        columns = data["columns"]
        expect(columns).to be_an(Array)

        name_col = columns.find { |c| c["name"] == "name" }
        expect(name_col).to include(
          "type" => "string",
          "nullable" => false
        )
      end

      it "includes column with default value" do
        columns = data["columns"]
        role_col = columns.find { |c| c["name"] == "role" }
        expect(role_col["default"]).to eq("member")
      end

      it "includes column limit" do
        columns = data["columns"]
        email_col = columns.find { |c| c["name"] == "email" }
        expect(email_col["limit"]).to eq(255)
      end

      it "includes indexes" do
        indexes = data["indexes"]
        expect(indexes).to be_an(Array)

        email_idx = indexes.find { |i| i["columns"] == ["email"] }
        expect(email_idx).to include("unique" => true)
      end

      it "includes associations" do
        associations = data["associations"]
        expect(associations).to be_an(Array)

        posts_assoc = associations.find { |a| a["name"] == "posts" }
        expect(posts_assoc).to include(
          "type" => "has_many",
          "name" => "posts"
        )
      end

      it "includes has_one associations" do
        associations = data["associations"]
        profile_assoc = associations.find { |a| a["name"] == "profile" }
        expect(profile_assoc).to include("type" => "has_one")
      end
    end

    context "with polymorphic associations" do
      subject(:data) { described_class.new(Comment).inspect_model }

      it "marks polymorphic associations" do
        associations = data["associations"]
        commentable = associations.find { |a| a["name"] == "commentable" }
        expect(commentable["polymorphic"]).to be true
      end
    end

    context "with HABTM associations" do
      subject(:data) { described_class.new(Post).inspect_model }

      it "includes HABTM as has_and_belongs_to_many" do
        associations = data["associations"]
        tags_assoc = associations.find { |a| a["name"] == "tags" }
        expect(tags_assoc["type"]).to eq("has_and_belongs_to_many")
      end
    end

    context "with self-referential associations" do
      subject(:data) { described_class.new(Category).inspect_model }

      it "includes parent association with class_name" do
        associations = data["associations"]
        parent_assoc = associations.find { |a| a["name"] == "parent" }
        expect(parent_assoc["class_name"]).to eq("Category")
      end

      it "includes children association" do
        associations = data["associations"]
        children_assoc = associations.find { |a| a["name"] == "children" }
        expect(children_assoc["type"]).to eq("has_many")
      end
    end

    context "with STI models" do
      subject(:data) { described_class.new(AdminUser).inspect_model }

      it "inspects STI subclass" do
        expect(data).to be_a(Hash)
        expect(data["metadata"]["table_name"]).to eq("users")
      end
    end

    context "with section filtering" do
      it "only includes configured sections" do
        Sidenotes.configure { |c| c.sections = %i[columns] }
        data = described_class.new(User).inspect_model
        expect(data.keys).to eq(["columns"])
      end

      it "includes metadata when configured" do
        Sidenotes.configure { |c| c.sections = %i[metadata columns] }
        data = described_class.new(User).inspect_model
        expect(data.keys).to contain_exactly("metadata", "columns")
      end
    end

    context "with abstract model" do
      it "returns nil for abstract models" do
        data = described_class.new(ApplicationRecord).inspect_model
        expect(data).to be_nil
      end
    end
  end
end
