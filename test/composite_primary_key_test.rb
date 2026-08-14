require "helper"

if ActiveRecord.version >= Gem::Version.create("7.1")
  class ShopProduct < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, use: :slugged
  end

  class ScopedShopProduct < ActiveRecord::Base
    self.table_name = "shop_products"
    extend FriendlyId
    friendly_id :name, use: :scoped, scope: :shop_id
  end

  class CompositePrimaryKeyTest < TestCaseClass
    include FriendlyId::Test

    def model_class
      ShopProduct
    end

    def create_product(name, shop_id: 1, product_ref: nil)
      model_class.create!(name: name, shop_id: shop_id, product_ref: product_ref || model_class.count + 1)
    end

    test "should generate a slug" do
      transaction do
        record = create_product("Salted Caramel")
        assert_equal "salted-caramel", record.slug
      end
    end

    test "should resolve conflicts against other records" do
      transaction do
        first = create_product("Salted Caramel")
        second = create_product("Salted Caramel")

        assert_equal "salted-caramel", first.slug
        refute_equal first.slug, second.slug
        assert second.slug.start_with?("salted-caramel-")
      end
    end

    test "should not consider a record a conflict with itself" do
      transaction do
        record = create_product("Salted Caramel")
        record.slug = nil
        record.save!

        assert_equal "salted-caramel", record.slug
      end
    end

    test "should find by friendly id" do
      transaction do
        record = create_product("Salted Caramel")
        assert_equal record, model_class.friendly.find("salted-caramel")
      end
    end

    test "should still find by the composite primary key" do
      transaction do
        record = create_product("Salted Caramel")
        assert_equal record, model_class.friendly.find(record.id)
      end
    end

    test "should raise when a friendly id is not found" do
      transaction do
        assert_raises(ActiveRecord::RecordNotFound) do
          model_class.friendly.find("nonexistent")
        end
      end
    end

    test "should allow the same slug in different scopes" do
      transaction do
        first = ScopedShopProduct.create!(name: "Salted Caramel", shop_id: 1, product_ref: 1)
        second = ScopedShopProduct.create!(name: "Salted Caramel", shop_id: 2, product_ref: 2)

        assert_equal "salted-caramel", first.slug
        assert_equal "salted-caramel", second.slug
      end
    end

    test "should resolve conflicts within a scope" do
      transaction do
        first = ScopedShopProduct.create!(name: "Salted Caramel", shop_id: 1, product_ref: 1)
        second = ScopedShopProduct.create!(name: "Salted Caramel", shop_id: 1, product_ref: 2)

        assert_equal "salted-caramel", first.slug
        refute_equal first.slug, second.slug
      end
    end
  end
end
