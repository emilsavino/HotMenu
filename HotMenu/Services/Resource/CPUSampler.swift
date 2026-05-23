import Darwin
import Foundation

enum CPUSampler {
    static func sample() -> CPUTicks? {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &info,
            &infoCount
        )

        guard result == KERN_SUCCESS, let info else { return nil }
        defer {
            let size = vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
        }

        var totals = CPUTicks(user: 0, system: 0, idle: 0, nice: 0)
        let stride = Int(CPU_STATE_MAX)

        for cpu in 0..<Int(cpuCount) {
            let base = cpu * stride
            totals.user &+= UInt64(info[base + Int(CPU_STATE_USER)])
            totals.system &+= UInt64(info[base + Int(CPU_STATE_SYSTEM)])
            totals.idle &+= UInt64(info[base + Int(CPU_STATE_IDLE)])
            totals.nice &+= UInt64(info[base + Int(CPU_STATE_NICE)])
        }

        return totals
    }
}
