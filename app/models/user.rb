class User < ApplicationRecord
  has_secure_password

  has_many :email_verification_tokens, dependent: :destroy
  has_many :password_reset_tokens, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :mentorship_roles_as_mentor, class_name: "Mentorship", foreign_key: "mentor_id"
  has_many :mentorship_roles_as_applicant, class_name: "Mentorship", foreign_key: "applicant_id"
  has_many :mentors, through: :mentorship_roles_as_mentor
  has_many :applicants, through: :mentorship_roles_as_applicant
  has_one :mentor_questionnaire, foreign_key: "respondent_id"
  has_one :mentee_questionnaire, foreign_key: "respondent_id"

  validates :email, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :password, allow_nil: true, length: {minimum: 12}
  validates :password, not_pwned: {message: "might easily be guessed"}
  validates :lat, numericality: {greater_than_or_equal_to: -90, less_than_or_equal_to: 90}, allow_nil: true
  validates :lng, numericality: {greater_than_or_equal_to: -180, less_than_or_equal_to: 180}, allow_nil: true

  enum unsubscribed_reason: {
    ghosted_mentor: "ghosted_mentor",
    ghosted_applicant: "ghosted_applicant",
    requested_removal: "requested_removal"
  }

  before_validation if: -> { email.present? } do
    self.email = email.downcase.strip
  end

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

  after_update if: :email_previously_changed? do
    events.create! action: "email_verification_requested"
  end

  after_update if: :password_digest_previously_changed? do
    events.create! action: "password_changed"
  end

  after_update if: [:verified_previously_changed?, :verified?] do
    events.create! action: "email_verified"
  end
end
