const std = @import("std");
var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const ArrayList = std.ArrayList;
const string = ArrayList(u8);
const strings = ArrayList(string);

const State = struct {
    file_list: strings = undefined,

    pub fn init(state: *State, allocator: std.mem.Allocator) !void {
        var args = try std.process.argsWithAllocator(allocator);
        defer args.deinit();
        state.file_list = strings.init(allocator);

        var arg_count: u32 = 0;
        while (args.next()) |arg| {
            arg_count += 1;
            if (arg_count != 1) {
                if (std.mem.indexOf(u8, arg, ".txt")) |_| {
                    try state.add_to_fl(arg, allocator);
                } else {
                    return error.UnknownArg;
                }
            }
        }
    }
    fn add_to_fl(
        state: *State,
        in_file: [:0]const u8,
        allocator: std.mem.Allocator,
    ) !void {
        var single_file = string.init(allocator);
        try single_file.appendSlice(in_file);
        try state.file_list.append(single_file);
    }
};
pub fn main() !void {
    const gpa = general_purpose_allocator.allocator();
    var state: State = .{};
    try state.init(gpa);

    const total_mem_req = try gpa.create(usize);
    for (state.file_list.items) |in_file| {
        const table = try read_sheet(gpa, in_file.items, total_mem_req);
        total_mem_req.* += table.items.len;
        var out_string = try table_to_string(table, gpa, total_mem_req.*);
        try fix_misshapen_percents(&out_string, gpa);
        try fix_space_after_newline(&out_string, gpa);
        try write_out(out_string, in_file.items, gpa);
        total_mem_req.* = 0;
    }
}
fn read_sheet(allocator: std.mem.Allocator, in_path: []const u8, total_mem: *usize) !strings {
    var table = strings.init(allocator);
    const startfile = try std.fs.cwd().openFile(in_path, .{});
    defer startfile.close();
    var buf_reader = std.io.bufferedReader(startfile.reader());
    var in_stream = buf_reader.reader();
    var total_size: usize = 0;
    var temp_col = string.init(allocator);

    while (true) {
        total_size += 1;
        const b = in_stream.readByte() catch {
            break;
        };
        switch (b) {
            ' ', '\n' => |c| {
                var entry = string.init(allocator);
                try entry.appendSlice(temp_col.items);
                try entry.append(',');
                try entry.append(c);
                temp_col.clearRetainingCapacity();
                try table.append(entry);
            },
            ',' => {},
            else => |c| {
                try temp_col.append(c);
            },
        }
    }
    total_mem.* = total_size;
    return table;
}
fn fix_misshapen_percents(buf: *string, allocator: std.mem.Allocator) !void {
    if (buf.items.len <= 6) {
        return error.StringTooShort;
    }
    var to_remove = ArrayList(usize).init(allocator);
    defer to_remove.deinit();
    for (0..buf.items.len - 6) |i| {
        const substring = buf.items[i .. i + 5];
        if (substring[0] == ' ' and
            is_digit(substring[1]) and
            substring[2] == ',' and
            substring[3] == ' ' and
            substring[4] == '%')
        {
            try to_remove.append(i + 2);
            try to_remove.append(i + 3);
        }
    }
    while (to_remove.popOrNull()) |i| {
        _ = buf.orderedRemove(i);
    }
}
fn fix_space_after_newline(buf: *string, allocator: std.mem.Allocator) !void {
    if (buf.items.len <= 4) {
        return error.StringTooShort;
    }
    var to_remove = ArrayList(usize).init(allocator);
    defer to_remove.deinit();
    for (0..buf.items.len - 4) |i| {
        const substring = buf.items[i .. i + 3];
        if (substring[0] == '\n' and
            substring[1] == ',' and
            substring[2] == ' ')
        {
            try to_remove.append(i + 1);
            try to_remove.append(i + 2);
        }
    }
    while (to_remove.popOrNull()) |i| {
        _ = buf.orderedRemove(i);
    }
}
fn table_to_string(table: strings, allocator: std.mem.Allocator, width: usize) !string {
    var buf = try string.initCapacity(allocator, width);
    for (0..table.items.len) |i| {
        try buf.appendSlice(table.items[i].items);
    }
    return buf;
}
fn is_digit(c: u8) bool {
    std.debug.assert('0' < '9');
    if (c <= '9' and c >= '0') return true;
    return false;
}
fn write_out(buf: string, in_path: []const u8, allocator: std.mem.Allocator) !void {
    var out_path: []u8 = try allocator.alloc(u8, in_path.len);
    if (std.mem.indexOf(u8, in_path, ".")) |i| {
        @memcpy(out_path[0 .. i + 1], in_path[0 .. i + 1]);
        @memcpy(out_path[i + 1 ..], "csv");
    }
    const out_file = try std.fs.cwd().createFile(out_path, .{});
    defer out_file.close();
    var writer = out_file.writer();
    try writer.print("{s}\n", .{buf.items});
}
