program gpuinfo;

uses
  Windows, SysUtils, OpenGL;

const
  VK_API_VERSION_1_0 = $00400000;
  VK_API_VERSION_1_1 = $00401000;
  VK_API_VERSION_1_2 = $00402000;
  VK_API_VERSION_1_3 = $00403000;
  VK_API_VERSION_1_4 = $00404000;

type
  TVkEnumerateInstanceVersion = function(var version: Cardinal): Integer; stdcall;

function FileVersionMajor(const Filename: string): Integer;
var
  Dummy, Len: DWORD;
  VerBuf: Pointer;
  VerSize: DWORD;
  FixedFileInfo: PVSFixedFileInfo;
  FixedSize: UINT;
begin
  Result := -1;
  VerSize := GetFileVersionInfoSize(PChar(Filename), Dummy);
  if VerSize = 0 then Exit;
  GetMem(VerBuf, VerSize);
  try
    if GetFileVersionInfo(PChar(Filename), 0, VerSize, VerBuf) then
      if VerQueryValue(VerBuf, '\', Pointer(FixedFileInfo), FixedSize) then
        Result := HiWord(FixedFileInfo.dwFileVersionMS);
  finally
    FreeMem(VerBuf);
  end;
end;

function GetDirectXVersion: string;
var
  sysDir: string;
begin
  sysDir := IncludeTrailingPathDelimiter(GetEnvironmentVariable('SystemRoot')) + 'System32\';

  if FileExists(sysDir + 'd3d12.dll') then Exit('DirectX 12');
  if FileExists(sysDir + 'd3d11.dll') then Exit('DirectX 11');
  if FileExists(sysDir + 'd3d10.dll') then Exit('DirectX 10');
  if FileExists(sysDir + 'd3d9.dll') then Exit('DirectX 9');
  if FileExists(sysDir + 'd3d8.dll') then Exit('DirectX 8');
  if FileExists(sysDir + 'd3d7.dll') then Exit('DirectX 7');
  if FileExists(sysDir + 'd3drm.dll') then Exit('DirectX 6');

  if FileExists(sysDir + 'd3d.dll') then
    case FileVersionMajor(sysDir + 'd3d.dll') of
      5: Exit('DirectX 5');
      3: Exit('DirectX 3');
    end;

  if FileExists(sysDir + 'ddraw.dll') then
    case FileVersionMajor(sysDir + 'ddraw.dll') of
      2: Exit('DirectX 2');
      1: Exit('DirectX 1');
    end;

  Result := 'DirectX not supported';
end;

function GetOpenGLVersion: string;
type
  TglGetString = function(name: Cardinal): PAnsiChar; stdcall;
var
  wc: WNDCLASS;
  hwnd: HWND;
  hDC: HDC;
  pfd: PIXELFORMATDESCRIPTOR;
  pf: Integer;
  hRC: HGLRC;
  glGetString: TglGetString;
  versionStr: string;
begin
  Result := 'OpenGL not supported';

  FillChar(wc, SizeOf(wc), 0);
  wc.lpfnWndProc := @DefWindowProc;
  wc.hInstance := HInstance;
  wc.lpszClassName := 'TempOpenGLWindow';
  if Windows.RegisterClass(wc) = 0 then Exit;

  hwnd := CreateWindow(wc.lpszClassName, 'Temp', 0, 0, 0, 1, 1, 0, 0, HInstance, nil);
  if hwnd = 0 then Exit;

  hDC := GetDC(hwnd);
  FillChar(pfd, SizeOf(pfd), 0);
  pfd.nSize := SizeOf(pfd);
  pfd.nVersion := 1;
  pfd.dwFlags := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
  pfd.iPixelType := PFD_TYPE_RGBA;
  pfd.cColorBits := 24;

  pf := ChoosePixelFormat(hDC, @pfd);
  if pf = 0 then Exit;
  if not SetPixelFormat(hDC, pf, @pfd) then Exit;

  hRC := wglCreateContext(hDC);
  if hRC = 0 then Exit;
  if not wglMakeCurrent(hDC, hRC) then Exit;

  glGetString := GetProcAddress(GetModuleHandle('opengl32.dll'), 'glGetString');
  if Assigned(glGetString) then
  begin
    versionStr := string(glGetString($1));
    versionStr := Copy(versionStr, 1, 3); // major.minor only
    Result := versionStr;
  end;

  wglMakeCurrent(0, 0);
  wglDeleteContext(hRC);
  ReleaseDC(hwnd, hDC);
  DestroyWindow(hwnd);
end;

function GetVulkanVersion: string;
var
  hVulkan: HMODULE;
  vkEnum: TVkEnumerateInstanceVersion;
  ver: Cardinal;
begin
  if FileExists(IncludeTrailingPathDelimiter(GetEnvironmentVariable('SystemRoot')) + 'System32\vulkan-sc.dll') or
     FileExists(IncludeTrailingPathDelimiter(GetEnvironmentVariable('SystemRoot')) + 'System32\vulkan-sc-1.dll') then
  begin
    Result := 'Vulkan SC 1.0';
    Exit;
  end;

  hVulkan := LoadLibrary('vulkan-1.dll');
  if hVulkan <> 0 then
  begin
    vkEnum := GetProcAddress(hVulkan, 'vkEnumerateInstanceVersion');
    if Assigned(vkEnum) then
    begin
      if vkEnum(ver) = 0 then
      begin
        case ver of
          VK_API_VERSION_1_0: Result := 'Vulkan 1.0';
          VK_API_VERSION_1_1: Result := 'Vulkan 1.1';
          VK_API_VERSION_1_2: Result := 'Vulkan 1.2';
          VK_API_VERSION_1_3: Result := 'Vulkan 1.3';
          VK_API_VERSION_1_4: Result := 'Vulkan 1.4';
        else
          Result := 'Vulkan unknown';
        end;
      end
      else
        Result := 'Vulkan 1.0';
    end
    else
      Result := 'Vulkan 1.0';
    FreeLibrary(hVulkan);
    Exit;
  end;

  Result := 'Vulkan not supported';
end;

var
  msg: string;
begin
  msg := GetDirectXVersion + #13#10 +
         GetOpenGLVersion + #13#10 +
         GetVulkanVersion;

  MessageBox(0, PChar(msg), 'GPU Info', MB_OK or MB_ICONINFORMATION);
end.
