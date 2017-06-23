class IntouchHandlerController < ActionController::Metal
  def handle
    IntouchHandlerWorker.perform_async(params)

    self.status = 200
    self.response_body = ''
  end
end
