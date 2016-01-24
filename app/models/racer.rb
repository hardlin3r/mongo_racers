class Racer
  include ActiveModel::Model
  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs

  def initialize(params = {})
    @id = params[:_id].nil? ? params[:id] : params[:_id].to_s
    @number = params[:number].to_i
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @gender = params[:gender]
    @group = params[:group]
    @secs = params[:secs].to_i
  end

  def persisted?
    !@id.nil?
  end

  def created_at
    nil
  end

  def updated_at
    nil
  end

  def destroy
    self.class.collection.find(number: @number).delete_one
  end

  def update(params)
    @number = params[:number].to_i
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @gender = params[:gender]
    @group = params[:group]
    @secs = params[:secs].to_i
    params.slice!(:number, :first_name, :last_name, :gender, :group, :secs) if ! params.nil?
    self.class.collection.find(_id: BSON::ObjectId.from_string(@id)).replace_one(params)
  end

  def save
    r = self.class.collection.insert_one(_id: @id,
                                          number: @number,
                                          first_name: @first_name,
                                          last_name: @last_name,
                                          gender: @gender,
                                          group: @group,
                                          secs: @secs)
    @id = r.inserted_id.to_s
  end

  def self.find id
    result = collection.find(_id: BSON::ObjectId.from_string(id.to_s) ).first
    return result.nil? ? nil : Racer.new(result)
  end
  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.collection
    mongo_client[:racers]
  end

  def self.all(prototype = {}, sort = {number: 1}, skip = 0, limit = nil)
    res = collection.find(prototype).sort(sort).skip(skip)
    res = res.limit(limit) if ! limit.nil?
    return res
  end

  def self.paginate(params)
    page = (params[:page] || 1).to_i
    limit = (params[:per_page] || 30).to_i
    skip = (page - 1) * limit
    racers = []
    all({}, {}, skip, limit).each do |r|
      racers << Racer.new(r)
    end
    total = all.count
    WillPaginate::Collection.create(page, limit, total) do |pager|
      pager.replace(racers)
    end
  end

end