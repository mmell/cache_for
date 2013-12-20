require "spec_helper"
require 'cache_for'

describe CacheFor::Base do

  describe "can read" do
    subject { CacheFor::Base.new } # the test environment must have a redis instance running on the default localhost:6379
    let(:now) { Time.now.to_s }
    let(:key) {__FILE__}

    it "what it wrote" do
      subject.write(key, now)
      subject.read(key).should == now
    end

    it "will not read what in did not write" do
      subject.read('aoue').should == subject.class::CacheMiss
    end

    describe ".cacheable?" do
      context "true" do
        it "string" do
          expect(subject.cacheable?("foo")).to be_true
        end
        it "array" do
          expect(subject.cacheable?([:a])).to be_true
        end
        it "hash" do
          expect(subject.cacheable?({a: 1})).to be_true
        end
        it "boolean true" do
          expect(subject.cacheable?(true)).to be_true
        end
        it "boolean false" do
          expect(subject.cacheable?(false)).to be_true
        end
      end

      context "false" do
        it "nil" do
          expect(subject.cacheable?(nil)).to be_false
        end
        it "empty string" do
          expect(subject.cacheable?("")).to be_false
        end
        it "empty array" do
          expect(subject.cacheable?([])).to be_false
        end
        it "empty hash" do
          expect(subject.cacheable?({})).to be_false
        end
      end

    end
  end
end
