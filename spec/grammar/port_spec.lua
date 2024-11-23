local grammar = require('sncl.grammar')

describe('Grammar #port element.', function ()
  it('Should be able to parse #port element', function ()
    local expect = {
      testPort = {
        _type = 'port',
        id = 'testPort',
        component = 'testComponent',
        interface = nil,
        line = 0,
      }
    }

      local snclString = [[
      port testPort testComponent
      ]]

      local result = grammar.lpegMatch(snclString)

      assert.are.same(expect, result.presentation)
  end)

  it('Should be able to parse #port element with an interface', function ()
    local expect = {
      testPort = {
        _type = 'port',
        id = 'testPort',
        component = 'testComponent',
        interface = 'interface',
        line = 1,
      }
    }

      local snclString = [[
      port testPort testComponent.interface
      ]]

      local result = grammar.lpegMatch(snclString)

      assert.are.same(expect, result.presentation)
  end)
end)