class AddUniqueIndexToReviews < ActiveRecord::Migration[8.0]
  def up
    duplicates = Review.select(:user_id, :order_item_id, :vegetable_id)
                       .group(:user_id, :order_item_id, :vegetable_id)
                       .having("count(*) > 1")

    if duplicates.any?
      say_with_time "Cleaning up duplicate reviews, keeping earliest..." do
        duplicates.each do |dup|
          reviews = Review.where(
            user_id: dup.user_id,
            order_item_id: dup.order_item_id,
            vegetable_id: dup.vegetable_id
          ).order(created_at: :asc).to_a

          keeper = reviews.shift
          say "  Keeping review ##{keeper.id} (user##{dup.user_id}, order_item##{dup.order_item_id})"
          reviews.each do |r|
            say "  Deleting duplicate review ##{r.id}"
            r.destroy
          end
        end
      end
    end

    remove_index :reviews, name: "index_reviews_on_user_id_and_order_item_id" if index_exists?(:reviews, [:user_id, :order_item_id], name: "index_reviews_on_user_id_and_order_item_id")

    add_index :reviews, [:user_id, :order_item_id, :vegetable_id],
      unique: true,
      name: "index_reviews_on_user_order_item_vegetable"
  end

  def down
    remove_index :reviews, name: "index_reviews_on_user_order_item_vegetable"
    add_index :reviews, [:user_id, :order_item_id], unique: true,
      name: "index_reviews_on_user_id_and_order_item_id"
  end
end
