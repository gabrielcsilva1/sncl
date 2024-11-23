local nclGen = require('sncl.generation')

describe('Generation #port element.', function ()
  it('Should generate #port element', function ()
    local mockPort = {
      _type = 'port',
      id = 'testPort',
      component = 'entry'
    }

    local expectedMockPortNCL = '<port id="testPort" component="entry"></port>'
    local result = nclGen:presentation(mockPort, {}, '')
    assert.are.equal(expectedMockPortNCL, result)
  end)
end)