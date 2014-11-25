require 'spec_helper'

describe 'Iterator2' do
  let(:a) { Array.new(2000000) }

  it 'iterates 2000000 times' do
    i = 0
    a.each { i += 1 }
    expect(i).to eq(2000000)
  end

  it 'compares 2000000 times' do
    a.each do
      expect(1).to eq(1)
    end
  end

  it 'compares 2000000 more times' do
    a.each do
      expect(1).to_not eq(2)
    end
  end
end
