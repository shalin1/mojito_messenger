class AdminMessageService
  def initialize(message)
    @body = message[:Body]
  end

  def handle

  end

  attr_reader :body
end