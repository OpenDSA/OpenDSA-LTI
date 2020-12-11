class ProfBooksController < ApplicationController
  def show
    @usr = User.all
    if ((params[:id].to_i) > 0)
      @usr = User.find(params[:id])
      puts "hello"
      unless @usr.nil?
        @books = InstBook.where(user_id: @usr.id)
      end
    end
  end
end
