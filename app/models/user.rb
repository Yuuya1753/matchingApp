class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable,
         :omniauthable

  mount_uploader :image, ImageUploader

  # 5MB以上のファイルはUPLOADできないように
  def size_range
    1..5.megabytes
  end

  has_many :footprints, foreign_key: 'user_id', dependent: :destroy
  has_many :joins, foreign_key: 'user_id'
  has_many :communities, through: :joins
  has_many :likes_from, class_name: "Like", foreign_key: 'user_id', dependent: :destroy
  has_many :likes_to, class_name: "Like", foreign_key: 'like_user_id', dependent: :destroy
  has_many :like_others, through: :likes_from, source: :like_other
  has_many :like_us, through: :likes_to, source: :like_me
  has_many :matches_from, class_name: "Match", foreign_key: 'from_user_id', dependent: :destroy
  has_many :matches_to, class_name: "Match", foreign_key: 'to_user_id', dependent: :destroy
  has_many :match_to_users, through: :matches_from, source: :match_to_user
  has_many :match_from_users, through: :matches_to, source: :match_from_user
  has_many :information, foreign_key: 'user_id'

  validates :name, uniqueness: true

  class << self
    def find_or_create_for_oauth(auth)
      created_user = find_or_create_by!(name: auth.info.name) do |user|
        user.provider = auth.provider
        user.uid = auth.uid
        user.name = auth.info.name
        user.email = User.dummy_email(auth)
        password = Devise.friendly_token[0..5]
        logger.debug password
        user.password = password
      end
      created_user.skip_confirmation!
      created_user.save
      created_user
    end


    def dummy_email(auth)
      "#{auth.uid}-#{auth.provider}@example.com"
    end

    # def new_with_session(params, session)
    #   if user_attributes = session['devise.user_attributes']
    #     new(user_attributes) { |user| user.attributes = params }
    #   else
    #     super
    #   end
    # end
  end
end
