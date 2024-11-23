local nclGen = require('sncl.generation')

describe('NCL Generation #context element.', function ()
  it('Should generate a #context element with #port children', function ()
    local mockContextTable = {
      _type = 'context',
      id = 'testContext',
      children = {
        {
          _type = 'port',
          id = 'testPort',
          component = 'entry'
        }
      }
    }
    local expectedMockContextNCL = '<context id="testContext">   <port id="testPort" component="entry">   </port></context>'
    local result = nclGen:presentation(mockContextTable, {}, '')
    assert.are.equal(expectedMockContextNCL, result)
  end)

  it('Should generate a #context element with #media children', function ()
    local mockContextTable = {
      _type = 'context',
      id = 'testContext',
      children = {
        {
          _type = 'media',
          id = 'testMedia'
        }
      }
    }
    local expectedMockContextNCL = '<context id="testContext">   <media id="testMedia">   </media></context>'
    local result = nclGen:presentation(mockContextTable, {}, '')
    assert.are.equal(expectedMockContextNCL, result)
  end)
end)