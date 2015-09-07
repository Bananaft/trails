Scene@ scene_;
Node@ cameraNode;
float yaw = 0.0f; // Camera yaw angle
float pitch = 0.0f; // Camera pitch angle

void Start()
{
   // log.level = 0;
    scene_ = Scene();
	CreateConsoleAndDebugHud();

	SubscribeToEvent("KeyDown", "HandleKeyDown");
    SubscribeToEvent("Update", "HandleUpdate");
    
	scene_.LoadXML(cache.GetFile("Scenes/scene.xml"));

	cameraNode = Node();
    Camera@ camera = cameraNode.CreateComponent("Camera");
    
	Viewport@ mainVP = Viewport(scene_, camera);
	renderer.viewports[0] = mainVP;
    
    MakeObjects();
}

void CreateConsoleAndDebugHud()
{
    // Get default style
    XMLFile@ xmlFile = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    if (xmlFile is null)
        return;

    // Create console
    Console@ console = engine.CreateConsole();
    console.defaultStyle = xmlFile;
    console.background.opacity = 0.8f;

    // Create debug HUD
    DebugHud@ debugHud = engine.CreateDebugHud();
    debugHud.defaultStyle = xmlFile;
}

void HandleKeyDown(StringHash eventType, VariantMap& eventData)
{
    int key = eventData["Key"].GetInt();

    // Close console (if open) or exit when ESC is pressed
    if (key == KEY_ESC)
    {
        if (!console.visible)
            engine.Exit();
        else
            console.visible = false;
    }

    // Toggle console with F1
    else if (key == KEY_F1)
        console.Toggle();

    // Toggle debug HUD with F2
    else if (key == KEY_F2)
        debugHud.ToggleAll();

    // Take screenshot
    else if (key == KEY_F12)
        {
            Image@ screenshot = Image();
            graphics.TakeScreenShot(screenshot);
            // Here we save in the Data folder with date and time appended
            screenshot.SavePNG(fileSystem.programDir + "Data/Screenshot_" +
                time.timeStamp.Replaced(':', '_').Replaced('.', '_').Replaced(' ', '_') + ".png");
        }

}

void MoveCamera(float timeStep)
{
    // Do not move if the UI has a focused element (the console)
    if (ui.focusElement !is null)
        return;

    // Movement speed as world units per second
    float MOVE_SPEED;
    if (input.keyDown[KEY_SHIFT]) MOVE_SPEED = 100.0f; else MOVE_SPEED = 10.0f;
    // Mouse sensitivity as degrees per pixel
    const float MOUSE_SENSITIVITY = 0.1f;

    // Use this frame's mouse motion to adjust camera node yaw and pitch. Clamp the pitch between -90 and 90 degrees
    IntVector2 mouseMove = input.mouseMove;
    yaw += MOUSE_SENSITIVITY * mouseMove.x;
    pitch += MOUSE_SENSITIVITY * mouseMove.y;
    pitch = Clamp(pitch, -90.0f, 90.0f);

    // Construct new orientation for the camera scene node from yaw and pitch. Roll is fixed to zero
    cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);

    // Read WASD keys and move the camera scene node to the corresponding direction if they are pressed
    if (input.keyDown['W'])
        cameraNode.Translate(Vector3(0.0f, 0.0f, 1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['S'])
        cameraNode.Translate(Vector3(0.0f, 0.0f, -1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['A'])
        cameraNode.Translate(Vector3(-1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['D'])
        cameraNode.Translate(Vector3(1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    // Take the frame time step, which is stored as a float
    float timeStep = eventData["TimeStep"].GetFloat();

    // Move the camera, scale movement with time step
    MoveCamera(timeStep);
}

void MakeObjects()
{
      
    Model@ rb_Model = Model();
    
   Geometry@ geom = Ribbon(50);

    
   rb_Model.numGeometries = 1;
   rb_Model.SetGeometry(0, 0, geom);
   rb_Model.boundingBox = BoundingBox(Vector3(-0.5, -0.5, -0.5), Vector3(0.5, 0.5, 0.5));
   
   Node@ node = scene_.CreateChild("rb_Model");
   node.position = Vector3(0.0, 0.0, 0.0);
    StaticModel@ object = node.CreateComponent("StaticModel");
   object.model = rb_Model;
}

Geometry@ Ribbon(uint16 numVertices)
{
    Array<float> vertexData(numVertices * 6, 0.0f);
    Array<uint16> indexData(numVertices);
    
    for (uint16 i = 0; i<numVertices; ++i) vertexData[i] = Random();
    
    for (uint16 i = 0; i<numVertices; ++i) indexData[i] = i;


    VertexBuffer@ vb = VertexBuffer();
    IndexBuffer@ ib = IndexBuffer();
    Geometry@ geom = Geometry();
    
    vb.shadowed = true;
    vb.SetSize(numVertices, MASK_POSITION|MASK_NORMAL);
    VectorBuffer temp;
    for (uint i = 0; i < numVertices * 6; ++i)
        temp.WriteFloat(vertexData[i]);
    vb.SetData(temp);

    ib.shadowed = true;
    ib.SetSize(numVertices, false);
    temp.Clear();
    for (uint i = 0; i < numVertices; ++i)
        temp.WriteUShort(indexData[i]);
    ib.SetData(temp);

    geom.SetVertexBuffer(0, vb);
    geom.SetIndexBuffer(ib);
    geom.SetDrawRange(TRIANGLE_LIST, 0, numVertices);

    return geom;
}