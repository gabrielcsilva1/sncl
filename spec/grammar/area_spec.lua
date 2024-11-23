local grammar = require('sncl.grammar')
describe('Grammar #area element.', function ()
  it('Should be able to parse an empty #area', function ()
    local expect = {
      testArea = {
        id = 'testArea',
        _type = 'area',
        properties = {},
        children = {},
        hasEnd = true,
        line = 0
      },
    }
    local snclString = [[
      area testArea end
    ]]
    local result = grammar.lpegMatch(snclString)
    assert.are.same(expect, result.presentation)
  end)
  it('Should be able to parse an #area with properties', function ()
    local expect = {
      testArea = {
        id = 'testArea',
        _type = 'area',
        properties = {
          begin = '5s'
        },
        children = {},
        hasEnd = true,
        line = 3
      }
    }
    local snclString = [[
    area testArea 
      begin: 5s
    end
    ]]
    local result = grammar.lpegMatch(snclString)
    assert.are.same(expect, result.presentation)
  end)
end)