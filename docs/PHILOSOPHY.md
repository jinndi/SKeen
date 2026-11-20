# SKeen's Philosophy

SKeen is not a visual configuration builder for sing-box — neither in whole nor in part. This is not a technical limitation, but a deliberate choice. Configuration is the core of sing-box: settings should remain explicit, predictable, and verifiable.

A graphical interface can simplify common scenarios and help people who are new to the subject. But a full route editor inevitably adds its own model on top of sing-box: some settings become hidden or unavailable, while rule order, priorities, and interactions become harder to understand.

That is why SKeen focuses on running sing-box, configuring network modes, and managing the firewall and configuration, while leaving routing rules in the sing-box configuration. This preserves the engine's capabilities and makes behavior explicit, testable, and debuggable.

Sub-Store plays an important role in this model. Obtaining subscriptions and preparing configurations from them is a separate task: SKeen consumes a prepared configuration and runs it with sing-box rather than trying to replace a subscription-management tool. In our view, there is currently no equally flexible and universal alternative. Knowing how to use Sub-Store is therefore not an optional extra but part of the basic workflow: it is where configurations used by SKeen are assembled and updated.

The same separation is reflected in the official sing-box graphical clients. The client receives a configuration in sing-box format, while converting source subscriptions into that format is a separate step that Sub-Store can perform. SKeen follows the same philosophy: it uses ready-to-run configurations and does not convert source subscriptions itself. Knowing how to use Sub-Store lets you use the prepared configurations with official sing-box clients as well as with SKeen.

This does not mean visual tools are useless or difficult to build. But building one merely to please an audience whose needs and approach to configuration I do not share would mean going against my own idea of the right solution. It would make sense to me only if I were the kind of user who wanted that level of simplification, or if the goal were to profit by reaching a broader audience. Neither is the purpose of SKeen: the project should remain a transparent, predictable tool without unnecessary abstraction.

Yes, this approach is not for beginners. If you are looking for a turnkey tool with routing configured through a simple interface, move along: SKeen is not for you. The sing-box community is still at an early stage, and that saddens me. But that is not the only reason: SKeen is intended for users who are willing to understand the configuration and related tools themselves.
