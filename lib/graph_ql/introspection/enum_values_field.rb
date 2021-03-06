GraphQL::Introspection::EnumValuesField = GraphQL::Field.new do |f, type, field, arg|
  f.description "Values for this enum"
  f.type type[!GraphQL::Introspection::EnumValueType]
  f.arguments({
    includeDeprecated: arg.build({type: GraphQL::BOOLEAN_TYPE, default_value: false})
  })
  f.resolve -> (object, arguments, context) {
    return nil if !object.kind.enum?
    fields = object.values.values
    if !arguments["includeDeprecated"]
      fields = fields.select {|f| !f.deprecation_reason }
    end
    fields
  }
end
