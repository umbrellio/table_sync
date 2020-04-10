# TableSync (development)

## Table of Content

- [Creation and registering of the new plugin](#creation-and-registering-of-the-new-plugin)

### Creation and registering of the new plugin

* Create a class inherited from `TableSync::Plugins::Abstract` (recomendation: place it in the plugins directory (`lib/plugins/`));
* Implement `.install!` method (`TableSync::Plugins::Abstract.install!`)
* Register new created class in plugins ecosystem (`TableSync.register_plugin('plugin_name', PluginClass))`);
* Usage: `TableSync.enable(:plugin_name)` / `TableSync.plugin(:plugin_name)` / `TableSync.load(:plugin_name)` (string name is supported too);

Example:

```ruby
# 1) creation (lib/plugins/global_method.rb)
class TableSync::Plugins::GlobalMethod < TableSync::Plugins::Abstract
  class << self
    # 2) plugin loader method implementation
    def install!
      ::TableSync.extend(Module.new do
        def global_method
          :works!
        end
      end)
    end
  end
end

# 3) plugin registration
TableSync.register('global_method', TableSync::Plugins::GlobalMethod)

# 4) enable registerd plugin
TableSync.plugin(:global_method) # string is supported too
# --- or ---
TableSync.enable(:global_method) # string is supported too
# --- or ---
TableSync.load(:global_method) # string is supported too

# Your new functionality
TableSync.global_method # => :works!
```
