GraphQL::Introspection::DirectiveType = GraphQL::ObjectType.new do |t, type, field|
  t.name "__Directive"
  t.description "A query directive in this schema"
  t.fields({
    name:         field.build(type: !type.String, desc: "The name of this directive"),
    description:  field.build(type: type.String, desc: "The description for this type"),
    args:         GraphQL::Introspection::ArgumentsField,
    onOperation:  field.build(type: !type.Boolean, property: :on_operation?, desc: "Does this directive apply to operations?"),
    onFragment:   field.build(type: !type.Boolean, property: :on_fragment?, desc: "Does this directive apply to fragments?"),
    onField:      field.build(type: !type.Boolean, property: :on_field?, desc: "Does this directive apply to fields?"),
  })
end
