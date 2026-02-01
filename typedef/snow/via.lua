---@meta

---@class via.clr.ManagedObject : via.Object
---@class via.Object : REManagedObject
---@class via.UserData : via.clr.ManagedObject
---@class via.gui.TransformObject : via.gui.PlayObject
---@class via.gui.PlayObject : via.clr.ManagedObject

---@class via.Size
---@field w System.Single
---@field h System.Single

---@class via.Component : via.clr.ManagedObject
---@field get_GameObject fun(self: via.Component): via.GameObject
---@field ToString fun(self: via.Component): System.String

---@class via.Behavior : via.Component
---@field get_Started fun(self: via.Behavior): System.Boolean
---@field get_Valid fun(self: via.Behavior): System.Boolean

---@class via.Scene : via.clr.ManagedObject
---@field get_FrameCount fun(self: via.Scene): System.UInt32

---@class via.SceneView : via.gui.TransformObject
---@field get_WindowSize fun(self: via.SceneView): via.Size

---@class via.gui.GUISystem : NativeSingleton
---@field get_MessageLanguage fun(self: via.gui.GUISystem): via.Language

---@class via.SceneManager : NativeSingleton
---@field get_MainView fun(self: via.SceneManager): via.SceneView
---@field get_CurrentScene fun(self: via.SceneManager): via.Scene

---@class via.Application : NativeSingleton
---@field get_DeltaTime fun(self: via.Application): System.Single

---@class via.GameObject : via.clr.ManagedObject
---@field get_Name fun(self: via.GameObject): System.String
---@field get_Transform fun(self: via.GameObject): via.Transform
---@field destroy fun(self: via.GameObject, object: via.GameObject)

---@class via.Transform : via.Component
---@field get_GameObject fun(self: via.Transform): via.GameObject
---@field get_Parent fun(self: via.Transform): via.Transform?
