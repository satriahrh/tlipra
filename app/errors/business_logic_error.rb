class BusinessLogicError < StandardError
  def initialize(message = "Business logic error occurred")
    super(message)
  end
end
