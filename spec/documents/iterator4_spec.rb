require 'spec_helper'

describe 'Iterator4' do
  let(:a) { Array.new(20000) }

  it 'iterates 20000 times' do
    i = 0
    a.each { i += 1 }
    expect(i).to eq(20000)
  end

  it 'compares 20000 times' do
    a.each do
      expect(1).to eq(1)
    end
  end

  it 'compares 20000 more times' do
    a.each do
      expect(1).to_not eq(2)
    end
  end
end
