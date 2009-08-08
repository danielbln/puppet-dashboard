require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. spec_helper]))

describe Service do
  describe 'attributes' do
    before :each do
      @service = Service.new
    end
    
    it 'should have a name' do
      @service.should respond_to(:name)
    end
    
    it 'should allow setting and retrieving the name' do
      @service.name = 'test name'
      @service.name.should == 'test name'
    end

    it 'should have a description' do
      @service.should respond_to(:description)
    end

    it 'should allow setting and retrieving the description' do
      @service.description = 'test description'
      @service.description.should == 'test description'
    end
  end

  describe 'validations' do
    before :each do
      @service = Service.new
    end

    it 'should require a name' do
      @service.name = nil
      @service.valid?
      @service.errors.should be_invalid(:name)
    end
    
    it 'should require name to be unique' do
      dup = Service.generate!(:name => 'unoriginal name')
      @service.name = 'unoriginal name'
      @service.valid?
      @service.errors.should be_invalid(:name)
    end

    it 'should be valid with an unique name' do
      @service.name = 'creative name'
      @service.valid?
      @service.errors.should_not be_invalid(:name)
    end
  end
  
  describe 'associations' do
    before :each do
      @service = Service.new
    end

    it 'should have many instances' do
      @service.should respond_to(:instances)
    end
    
    it 'should allow assigning instances' do
      @instance = Instance.generate!
      @service.instances << @instance
      @service.instances.should include(@instance)
    end
    
    it 'should have many deployments' do
      @service.should respond_to(:deployments)
    end
    
    it "should return its instances' deployments when looking up deployments" do
      @deployments = Array.new(2) { Deployment.generate! }
      @service.instances << @deployments.collect(&:instance)
      @service.deployments.sort_by(&:id).should == @deployments.sort_by(&:id)
    end
        
    it 'should have many hosts' do
      @service.should respond_to(:hosts)
    end
    
    it "should return its instances' hosts when looking up hosts" do
      @deployments = Array.new(2) { Deployment.generate! }
      @service.instances << @deployments.collect(&:instance)
      @service.hosts.sort_by(&:id).should == @deployments.collect(&:host).sort_by(&:id)      
    end

    it 'should have many apps' do
      @service.should respond_to(:apps)      
    end
    
    it "should return its instances' apps when looking up apps" do
      @instances = Array.new(2) { Instance.generate! }
      @service.instances << @instances
      @service.apps.sort_by(&:id).should == @instances.collect(&:app).sort_by(&:id)            
    end
    
    it 'should have many customers' do
      @service.should respond_to(:customers)
    end
    
    it "should return its instances' customers when looking up customers" do
      @instances = Array.new(2) { Instance.generate! }
      @service.instances << @instances
      @service.customers.sort_by(&:id).should == @instances.collect(&:customer).sort_by(&:id)      
    end
  end
  
  describe 'relationships' do
    before :each do
      @service = Service.new
    end

    it 'should have many edges as a source' do
      @service.should respond_to(:source_edges)
    end

    it 'should allow assigning edges as a source' do
      @service = Service.generate!
      @service.source_edges.generate!
      @service.source_edges.should_not be_empty
    end

    it 'should have many edges as a target' do
      @service.should respond_to(:target_edges)
    end

    it 'should allow assigning edges as a target' do
      @service = Service.generate!
      @service.target_edges.generate!
      @service.target_edges.should_not be_empty
    end
    
    it 'should have many "depends on" edges' do
      @service.should respond_to(:depends_on_edges)
    end

    it 'should allow assigning "depends on" edges' do
      @service = Service.generate!
      @service.depends_on_edges.generate!
      @service.depends_on_edges.should_not be_empty
    end

    it 'should have many "dependent" edges' do
      @service.should respond_to(:dependent_edges)
    end

    it 'should allow assigning "dependent" edges' do
      @service = Service.generate!
      @service.dependent_edges.generate!
      @service.dependent_edges.should_not be_empty
    end

    it 'should have many services it depends on' do
      @service.should respond_to(:depends_on)
    end

    it 'should allow assigning services it depends on' do
      @service = Service.generate!
      @other = Service.generate!
      @service.depends_on << @service
      @service.depends_on.should include(@service)
    end

    it 'should have many dependent services' do
      @service.should respond_to(:dependents)
    end

    it 'should allow assigning dependent services' do
      @service = Service.generate!
      @other = Service.generate!
      @other.dependents << @service
      @other.dependents.should include(@service)
    end
    
    it 'should be able to find all services it depends on' do
      @service.should respond_to(:all_depends_on)
    end
    
    it 'should be able to find all services that depend on it' do
      @service.should respond_to(:all_dependents)
    end
    
    describe 'with dependencies' do
      before :each do
        @service     = Service.generate!(:name => 'service')
        @parent      = Service.generate!(:name => 'parent')
        @grandparent = Service.generate!(:name => 'grandparent')
        @child       = Service.generate!(:name => 'child')
        @grandchild  = Service.generate!(:name => 'grandchild')
        @service.dependents << @parent
        @parent.dependents  << @grandparent
        @service.depends_on << @child
        @child.depends_on   << @grandchild
      end
      
      it 'should not include itself when finding all services it depends on' do
        @service.all_depends_on.should_not include(@service)
      end
      
      it 'should include services that it directly depends on when finding all services that it depends on' do
        @service.all_depends_on.should include(@child)
      end
    
      it 'should return all reachable services when finding all services that it depends on' do
        @service.all_depends_on.should include(@grandchild)      
      end
      
      it 'should only return a single instance of a service that appears multiple times when finding all services that it depends on' do
        @service.depends_on << @grandchild
        @service.all_depends_on.select {|s| s == @grandchild }.size.should == 1
      end
    
      it 'should not include itself when finding all services it depends on' do
        @service.all_dependents.should_not include(@service)
      end
    
      it 'should include services that directly depend on it when finding all services that depend on it' do
        @service.all_dependents.should include(@parent)
      end

      it 'should return all reachable services when finding all services that depend on it' do
        @service.all_dependents.should include(@grandparent)
      end

      it 'should only return a single instance of a service that appears multiple times when finding all services that depend on it' do
        @service.dependents << @grandparent
        @service.all_dependents.select {|s| s == @grandparent }.size.should == 1
      end
      
      it 'should be able to tell if a service is a root service' do
        @service.should respond_to(:root?)
      end
      
      it 'should not be a root service if it has services which depend on it' do
        @grandparent.should be_root
      end
      
      it 'should be a root service if it has no services which depend on it' do
        @parent.should_not be_root
      end
      
      it 'should be able to tell if a service is a leaf service' do
        @service.should respond_to(:leaf?)
      end
      
      it 'should not be a leaf service if it has services which it depends on' do
        @grandchild.should be_leaf
      end
      
      it 'should be a leaf service if it has no services which it depends on' do
        @child.should_not be_leaf
      end
    end    
  end
  
  it 'should be able to generate a configuration name' do
    Service.new.should respond_to(:configuration_name)
  end
  
  describe 'when generating a configuration name' do
    before :each do
      @service = Service.generate!
    end
    
    it 'should work without arguments' do
      lambda { @service.configuration_name }.should_not raise_error(ArgumentError)
    end
    
    it 'should not allow arguments' do
      lambda { @service.configuration_name(:foo) }.should raise_error(ArgumentError)
    end
   
    it 'should not be empty' do
      @service.configuration_name.should_not be_blank
    end
    
    it 'should vary the name when its name varies' do
      original_name = @service.configuration_name
      @service.name = @service.name.succ
      @service.configuration_name.should_not == original_name
    end
    
    it 'should include only lowercase alphanumerics and underscores' do
      @service.name = 'Some Service 123:::!!!'
      @service.configuration_name.should == 'some_service_123'            
    end
  end
end
