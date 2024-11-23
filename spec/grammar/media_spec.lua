local grammar = require('sncl.grammar')

describe('#grammar #media element', function()

  it('Should parse a empty #media', function()
    local expected = {
      presentation = {
        testMedia = {
          _type = 'media',
          id = 'testMedia',
          hasEnd = true,
          properties = {},
          children = {},
          line = 1
        }
      }
    }
    local snclString = [[
    media testMedia
    end
    ]]
    local result = grammar.lpegMatch(snclString)
    assert.are.same(expected.presentation, result.presentation)
  end)

  it('Should parse a #media with src attribute', function()
    local expected = {
      testMediaAttributes = {
          _type = 'media',
          id = 'testMediaAttributes',
          src = '../images/testImage.png',
          hasEnd = true,
          properties = {},
          children = {},
          line = 4
        }
      }

    local snclString = [[
    media testMediaAttributes
      src: "../images/testImage.png"
    end
    ]]
    local result = grammar.lpegMatch(snclString)
    assert.are.same(expected, result.presentation)
  end)

  it('Should parse #media with properties', function ()
    local expected =  {
      testMediaProperties = {
          _type = 'media',
          id = 'testMediaProperties',
          hasEnd = true,
          properties = {
            focusIndex = '1',
            focusBorderWidth = '3',
            right = '10%',
          },
          children = {},
          line = 9
        }
      }

    local snclString = [[
    media testMediaProperties
      focusIndex: 1
      focusBorderWidth: 3
      right: 10% 
    end
    ]]
    local result = grammar.lpegMatch(snclString)
    assert.are.same(expected, result.presentation)
  end)

  it('Should parse #media with a rg attribute', function ()
    local expect = {
      testMediaAttributes = {
        _type = 'media',
        id = 'testMediaAttributes',
        region = 'screen',
        descriptor = '__desc__screen',
        properties = {},
        children = {},
        hasEnd = true,
        line = 12,
      }
    }

    local snclString = [[
    media testMediaAttributes
      rg: screen
    end
    ]]

    local result = grammar.lpegMatch(snclString)

    assert.are.same(expect, result.presentation)
  end)

  it('Should parse #media with #area children', function ()
    local area = {
      _type = 'area',
      id = 'testArea',
      properties = {},
      children = {},
      hasEnd = true,
      line = 14
    }

    local media = {
      _type = 'media',
      id = 'testMedia',
      properties = {},
      children = {
        area
      },
      hasEnd = true,
      line = 15,
    }

    area.father = media

    local expect = {
      testMedia = media,
      testArea = area
    }

    local snclString = [[
    media testMedia
      area testArea end
    end
    ]]

    local result = grammar.lpegMatch(snclString)
    assert.are.same(expect, result.presentation)
  end)

end)

