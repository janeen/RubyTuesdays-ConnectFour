class Game < ActiveRecord::Base
  # This includes the methods in mixins/game/board_mixin.rb as class methods.
  # Check this file out for some helpful functions!
  extend Game::BoardMixin
  include Game::BoardMixin

  ### Constants ###

  # These define the size of the board. Remember: we index from 0, so valid
  # board coordinates are between [0,0] to [NUM_COLUMNS - 1 , NUM_ROWS - 1]
  NUM_ROWS = 6
  NUM_COLUMNS = 7

  ### Associations ###
  serialize :board, JSON

  # Security (ActiveModel::MassAssignmentSecurity)
  attr_accessible :board, :created_at, :status, :current_player

  ### Scopes ###
  scope :in_progress, where(:status => :in_progress)
  scope :finished,    where(:status => %w(red blue tie))
  scope :won, where(:status => %w(red blue))
  scope :tie, where(:status => :tie)

  ### Callbacks ###

  ### Validations ###
  validates_inclusion_of :status, :allow_blank => false,
                                  :in => %w(in_progress blue red tie)
  validates_with BoardValidator, :dimensions => [NUM_COLUMNS, NUM_ROWS]



  # Sets current_player to 'blue' iff current_player has not been initialized
  def initialize(*args)
    super(*args)

    # initialize variables
    # NOTE: Add all initialization here!
    self.board = (0...NUM_COLUMNS).map{[]}
    self.current_player = 'blue' unless self.current_player.present?
    self.status = 'in_progress' unless self.status.present?
  end

  # Gets the next player
  # @return [String] The next player
  def next_player
    nextplayer = " "
	if self.current_player == "blue"
	  nextplayer = "red"
	else
	  nextplayer = "blue"
	end
    return nextplayer
  end

  # setNextPlayer sets the next player
  #
  # @return [String] The new player
  def set_next_player
    self.current_player = next_player
	return self.current_player
  end

  # returns the piece at the coordinates
  def board_position(coords)
    col, row = coords

    unless coords_valid?(coords)
      raise ArgumentError, "Coords [#{col}][#{row}] are out of bounds."
    end

	# check if there is a piece present
	if row < board[col].length
      return self.board[col][row]
	else
	  return nil
	end
  end


  # checks that the given coordinates are within the valid range
  def coords_valid?(coords)
    col, row = coords
	
	if ((col >=0 && col < NUM_COLUMNS) && (row >=0 && row < NUM_ROWS))
		return true
	else
		return false
	end

  end

  # MakeMove takes a column and player and updates the board to reflect the
  # given move. Also will update :current_player and :status
  #
  # @param column [Integer]
  # @param player [String] either 'red' or 'blue'
  def make_move(column, player)

	# make sure column is valid
	unless column >= 0 && column < NUM_COLUMNS - 1
      raise ArgumentError, "Column [#{column}]is out of bounds."
	end
	
	# make sure column is not full
	unless board[column].length < NUM_ROWS
      raise ArgumentError, "Column [#{column}] is full - cannot add another piece."
	end
	
	# make sure player is red or blue
	unless player == 'red' or player == 'blue' or player == :red or player == :blue
      raise ArgumentError, "Player, #{player}, is not valid.  Allowed values are 'red' or 'blue'."
	end
	
	# got this far - update the board
	row = board[column].length # this should be the next available index in the row array
	self.board[column][row]=player

	# check for a winner
	self.status = check_for_winner
	if self.status == 'in_progress' or self.status == :in_progress
	  set_next_player  # if no winner, set the next player
	end
	
  end

  # Checks if there is a winner and returns the player if it exists
  #
  # @return [String] 'red', 'blue', 'tie', 'draw', or 'in_progress'
  def check_for_winner
    # TODO
	
	
	# check to see if latest move has resulted in a win for a player 
    # don't have the coordinates of the latest move, so we need to check the whole board
	binding.pry
	# check each horizontal row
	for i in 0...NUM_ROWS
	  for j in 0..(NUM_COLUMNS-4)  # this is inclusive!
	    binding.pry
	    puts "coords #{j}, #{i}: #{board_position([j,i])}"
	    if( board_position([j,i]) != nil &&
		    board_position([j,i]) == board_position(Game.horizontal([j,i],1)) &&
		    board_position([j,i]) == board_position(Game.horizontal([j,i],2)) &&
		    board_position([j,i]) == board_position(Game.horizontal([j,i],3)) )
		  return board_position([j,i]) # they won
		end
	  end
	end
	
	# check each vertical row
	for j in 0...NUM_COLUMNS
	  row = board[j]
	  if row.length >= 4  # starting looking for 4 in a row vertically
		for i in 0..(row.length-4)
			if( board_position([j,i]) != nil &&
				board_position([j,i]) == board_position(Game.vertical([j,i],1)) &&
				board_position([j,i]) == board_position(Game.vertical([j,i],2)) &&
				board_position([j,i]) == board_position(Game.vertical([j,i],3)) )
			  return board_position([j,i]) # they won
			end		  
		end
	  end
	end
	
    # check diagonals - this only checks diagonal up (not down)
	for i in 0..(NUM_ROWS-4)
  	  for j in 0..(NUM_COLUMNS-4)
		if( board_position([j,i]) != nil &&
			board_position([j,i]) == board_position(Game.diagonal([j,i],1)) &&
			board_position([j,i]) == board_position(Game.diagonal([j,i],2)) &&
			board_position([j,i]) == board_position(Game.diagonal([j,i],3)) )
		  return board_position([j,i]) # they won
		end
	  end
	end
	
	# check to see if the board is now full and no one won - then it is a tie
    running_sum = 0
	for j in 0...NUM_COLUMNS
	  running_sum += board[j].length
	end
	if running_sum == (NUM_COLUMNS) * (NUM_ROWS)
	  # we have a full board
	  return :tie
	end
	
	# if no one has won and board not full, then game is still in_progress
    return :in_progress
	
  end



  #############################################################################

  private

  # NOTE: Put all helper-methods here!


end
