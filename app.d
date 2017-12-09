import std.stdio;
import std.process;
import std.conv;
import std.string;
import std.traits;


struct _sysInfo {
	string username;
	int coreCount;
	ulong ram;
	string arch;
	string[string] storageDeviceSpace;
	string[] users;
	string homeDirectory;
};	


string getHomeDirectory()
{
	return strip("echo $HOME".executeShell.output);
}

int getCores()
{
	return to!int(strip(["nproc"].execute.output));
}

string getUsername()
{
	return strip(["whoami"].execute.output);
}

string[string] getStorageDevices()
{
	string[] devices = splitLines(["lsblk", "-l"].execute.output)[1 .. $];
	string[string] map;

	foreach (el; devices)
	{
		auto groups = el.split;
		string name = groups[0];
		string size = groups[3];
		string type = groups[5];
		
		if (type != "disk")
			continue;
		
		map[name] = size;
	}
	
	return map;
}

ulong getRAM()
{
	return to!ulong(strip("awk '/MemTotal/ {print $2}' /proc/meminfo".executeShell.output));
}

string getArch()
{
	return strip(["uname", "-m"].execute.output);
}

string[] getUsers()
{
	string[] unparsed = splitLines(["cat", "/etc/passwd"].execute.output);
	string[] users;

	foreach (line; unparsed)
		users ~= line.split(":")[0];	

	return users;
}

void main()
{
	_sysInfo *sysInfo = new _sysInfo;
	sysInfo.username = getUsername();
	sysInfo.coreCount = getCores();
	sysInfo.arch = getArch();
	sysInfo.storageDeviceSpace = getStorageDevices();
	sysInfo.users = getUsers();
	sysInfo.homeDirectory = getHomeDirectory();
	sysInfo.ram = getRAM();
	sysInfo.ram /= 1048576;
	foreach (member; __traits(allMembers, _sysInfo))
	{
		auto val = __traits(getMember, sysInfo, member);
		
		static if (isDynamicArray!(typeof(val)) &&
		    !isSomeString!(typeof(val)) &&
		    !isIntegral!(typeof(val)))
		{
			writefln("%s) ", member);
			foreach (el; val)
				writefln("\t%s -> ... -> %s", member, el);
		} else static if (is(typeof(val) == string[string])) {
			writefln("%s) ", member);
			foreach (k, v; val)
				writefln("\t%s -> %s", k, v);
		} else {
			writefln("%s) %s", member, val);
		}
	}
}
