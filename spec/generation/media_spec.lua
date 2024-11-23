local nclGen = require('sncl.generation')
describe('NCL #generation #media element.', function()
  it('Should generate a #media with attributes', function()
    local mockMedia = {
      _type = 'media',
      id = 'testMedia',
      src = 'testImage.png',
    }
    local expectedMockMediaNCL = '<media id="testMedia" src="testImage.png"></media>'
    local result = nclGen:presentation(mockMedia, {}, '')
    assert.are.equal(expectedMockMediaNCL, result)
  end)
  it('Should generate a #media with properties', function()
    local mockMedia = {
      _type = 'media',
      id = 'testMedia',
      properties = { left = '10%' }
    }
    local expectedMockMediaNCL = '<media id="testMedia">   <property name="left" value="10%" /></media>'
    local result = nclGen:presentation(mockMedia, {}, '')
    assert.are.equal(expectedMockMediaNCL, result)
  end)
  it('Should generate a #media with #area children', function ()
    local mockMedia = {
      _type = 'media',
      id = 'testMedia',
      children ={
        {
          _type = 'area',
          id = 'testArea',
          properties = {
            begin = '5s'
          }
        }
      }
    }
    local expectedMockMediaNCL = '<media id="testMedia">   <area id="testArea" begin="5s" /></media>'
    local result = nclGen:presentation(mockMedia, {}, '')
    assert.are.equal(expectedMockMediaNCL, result)
  end)
end)