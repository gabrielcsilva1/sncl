local grammar = require('sncl.grammar')

describe('Grammar #context element.', function ()
  it('Should be able to parse a empty #context', function ()
    local expect = {
      testContext = {
        id = 'testContext',
        _type = 'context',
        properties = {},
        children = {},
        hasEnd = true,
        line = 0
      }
    }

    local snclString = [[
    context testContext end
    ]]

    local result = grammar.lpegMatch(snclString)

    assert.are.same(expect, result.presentation)
  end)

  it('Should be able to parse #context with a #media children', function ()
    local media = {
      _type = 'media',
      id = 'testMedia',
      properties = {},
      children = {},
      hasEnd = true,
      line = 2,
    }

    local context = {
      id = 'testContext',
      _type = 'context',
      properties = {},
      children = {
        media
      },
      hasEnd = true,
      line = 3
    }

    media.father = context
    
    local expect = {
      testContext = context,
      testMedia = media
    }

    local snclString = [[
    context testContext 
      media testMedia end
    end
    ]]

    local result = grammar.lpegMatch(snclString)

    assert.are.same(expect, result.presentation)
  end)

  it('Should be able to parse #context with a #port children', function ()
    local port = {
      _type = 'port',
      id = 'testPort',
      component = 'entryMedia',
      line = 5,
    }

    local context = {
      id = 'testContext',
      _type = 'context',
      properties = {},
      children = {
        port
      },
      hasEnd = true,
      line = 6
    }

    port.father = context
    
    local expect = {
      testContext = context,
      testPort = port
    }

    local snclString = [[
    context testContext 
      port testPort entryMedia
    end
    ]]

    local result = grammar.lpegMatch(snclString)

    assert.are.same(expect, result.presentation)
  end)
end)