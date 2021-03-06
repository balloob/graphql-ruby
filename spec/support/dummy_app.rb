require_relative './dummy_data'

EdibleInterface = GraphQL::Interface.new do |i, type, field|
  i.name "Edible"
  i.description "Something you can eat, yum"
  i.fields({
    fatContent: field.build(
      type: !type.Float,
      property: :non_existent_field_that_should_never_be_called,
      desc: "Percentage which is fat"),
  })
end

AnimalProductInterface = GraphQL::Interface.new do |i, type, field|
  i.name "AnimalProduct"
  i.description "Comes from an animal, no joke"
  i.fields({
    source: field.build(type: !type.String, desc: "Animal which produced this product"),
  })
end

DairyAnimalEnum = GraphQL::Enum.new do |e|
  e.name "DairyAnimal"
  e.description "An animal which can yield milk"
  e.value("COW",    "Animal with black and white spots")
  e.value("GOAT",   "Animal with horns")
  e.value("SHEEP",  "Animal with wool")
  e.value("YAK",    "Animal with long hair", deprecation_reason: "Out of fashion")
end

CheeseType = GraphQL::ObjectType.new do |t, type, field, arg|
  t.name "Cheese"
  t.description "Cultured dairy product"
  t.interfaces [EdibleInterface, AnimalProductInterface]
  t.fields = {
    id:           field.build(type: !type.Int, desc: "Unique identifier"),
    flavor:       field.build(type: !type.String, desc: "Kind of cheese"),
    source:       field.build(type: !DairyAnimalEnum, desc: "Animal which produced the milk for this cheese"),
    similarCheeses: GraphQL::Field.new do |f|
      f.description "Cheeses like this one"
      f.type(t)
      f.arguments({source: arg.build(type: !type[!DairyAnimalEnum])})
      f.resolve -> (t, a, c) { CHEESES.values.find { |c| c.source == a["source"] } }
    end,
    fatContent:   field.build(type: !type.Float, desc: "Percentage which is milkfat", deprecation_reason: "Diet fashion has changed"),
  }
end

MilkType = GraphQL::ObjectType.new do |t, type, field, arg|
  t.name 'Milk'
  t.description "Dairy beverage"
  t.interfaces [EdibleInterface, AnimalProductInterface]
  t.fields = {
    id:           field.build(type: !type.ID, desc: "Unique identifier"),
    source:       field.build(type: DairyAnimalEnum, desc: "Animal which produced this milk"),
    fatContent:   field.build(type: !type.Float, desc: "Percentage which is milkfat"),
    flavors:      field.build(
          type: type[type.String],
          desc: "Chocolate, Strawberry, etc",
          args: {limit: arg.build({type: type.Int})}
        ),
  }
end

DairyProductUnion = GraphQL::Union.new(
  "DairyProduct",
  "Kinds of food made from milk",
  [MilkType, CheeseType]
)

DairyProductInputType = GraphQL::InputObjectType.new {|t, type, field, arg|
  t.name "DairyProductInput"
  t.description "Properties for finding a dairy product"
  t.input_fields({
    source:     arg.build({type: DairyAnimalEnum}),
    fatContent: arg.build({type: type.Float}),
  })
}


class FetchField
  attr_reader :type, :arguments, :deprecation_reason
  attr_accessor :name
  def initialize(type:, data:, id_type: !GraphQL::INT_TYPE)
    @type = type
    @data = data
    @arguments = {"id" => GraphQL::InputValue.new(type: id_type, name: "id")}
    @deprecation_reason = nil
  end

  def description
    "Find a #{@type.name} by id"
  end

  def resolve(target, arguments, context)
    @data[arguments["id"].to_i]
  end
end

SourceField = GraphQL::Field.new do |f, type, field, arg|
  f.type GraphQL::ListType.new(of_type: CheeseType)
  f.description "Cheese from source"
  f.arguments(source: arg.build(type: !DairyAnimalEnum))
  f.resolve -> (target, arguments, context) {
    CHEESES.values.select{ |c| c.source == arguments["source"] }
  }
end

FavoriteField = GraphQL::Field.new do |f|
  f.description "My favorite food"
  f.type EdibleInterface
  f.resolve -> (t, a, c) { MILKS[1] }
end


QueryType = GraphQL::ObjectType.new do |t, types, field, arg|
  t.name "Query"
  t.description "Query root of the system"
  t.fields({
    cheese: FetchField.new(type: CheeseType, data: CHEESES),
    milk: FetchField.new(type: MilkType, data: MILKS, id_type: !types.ID),
    fromSource: SourceField,
    favoriteEdible: FavoriteField,
    searchDairy: GraphQL::Field.new { |f|
      f.name "searchDairy"
      f.description "Find dairy products matching a description"
      f.type !DairyProductUnion
      f.arguments({product: arg.build({type: DairyProductInputType})})
      f.resolve -> (t, a, c) {
        products = CHEESES.values + MILKS.values
        source =  a["product"]["source"]
        if !source.nil?
          products = products.select { |p| p.source == source }
        end
        products.first
      }
    },
    error: GraphQL::Field.new { |f|
      f.description "Raise an error"
      f.type GraphQL::STRING_TYPE
      f.resolve -> (t, a, c) { raise("This error was raised on purpose") }
    },
  })
end

GLOBAL_VALUES = []

MutationType = GraphQL::ObjectType.new do |t, type, field, arg|
  t.name "Mutation"
  t.description "The root for mutations in this schema"
  t.fields({
    pushValue: GraphQL::Field.new { |f|
      f.description("Push a value onto a global array :D")
      f.type(!type[!type.Int])
      f.arguments(value: arg.build(type: !type.Int))
      f.resolve -> (o, args, ctx) {
        GLOBAL_VALUES << args["value"]
        GLOBAL_VALUES
      }
    }
  })
end

DummySchema = GraphQL::Schema.new(query: QueryType, mutation: MutationType)
