pragma(lib, "kernel32.lib");
pragma(lib,"user32.lib");
import std.stdio;
import core.sys.windows.windows;
import std.utf : toUTF16z, toUTF8;
import std.conv : to;
import std.array : replace;
import core.stdc.wchar_ : wcslen;
import core.thread : Thread, msecs;

void setConsoleToUTF8() {
    SetConsoleOutputCP(65001); // UTF-8代码页
}

void replaceInClipboard(string findStr, string replaceStr) {
    // 打开剪贴板
    if (OpenClipboard(null) == 0) {
        writeln("无法打开剪贴板");
        return;
    }
    scope(exit) CloseClipboard();

    // 尝试获取Unicode文本
    HANDLE hData = GetClipboardData(CF_UNICODETEXT);
    if (hData == null) {
        writeln("剪贴板中没有文本数据或获取失败");
        return;
    }

    // 锁定全局内存并获取文本指针
    wchar* pszText = cast(wchar*)GlobalLock(hData);
    if (pszText == null) {
        writeln("无法锁定全局内存");
        return;
    }
    scope(exit) GlobalUnlock(hData);

    // 转换为D字符串并替换内容
    wstring clipboardText = pszText[0 .. wcslen(pszText)].idup;
    string text = to!string(clipboardText);
    string newText = text.replace(findStr, replaceStr);

    // 分配新的全局内存
    wchar[] newWText = to!wstring(newText).dup;
    HGLOBAL hNewData = GlobalAlloc(GMEM_MOVEABLE, (newWText.length + 1) * wchar.sizeof);
    if (hNewData == null) {
        writeln("内存分配失败");
        return;
    }

    // 复制数据到新内存
    wchar* pNewData = cast(wchar*)GlobalLock(hNewData);
    if (pNewData == null) {
        GlobalFree(hNewData);
        writeln("无法锁定新内存");
        return;
    }
    pNewData[0 .. newWText.length] = newWText[];
    pNewData[newWText.length] = '\0';
    GlobalUnlock(hNewData);

    // 清空并更新剪贴板
    EmptyClipboard();
    if (SetClipboardData(CF_UNICODETEXT, hNewData) == null) {
        GlobalFree(hNewData);
        writeln("设置剪贴板数据失败");
    }
}

void main() {
    setConsoleToUTF8();
    // 示例：替换所有"old"为"new"
    while (true){
        replaceInClipboard("preview", "index");
        writeln("剪贴板内容已更新");
        Thread.sleep(500.msecs);
    }
}
