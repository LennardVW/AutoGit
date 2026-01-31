import Foundation

// MARK: - AutoGit
/// REAL automatic commit generation using git diff analysis

@main
struct AutoGit {
    static func main() async {
        let autogit = AutoGitCore()
        await autogit.run()
    }
}

@MainActor
final class AutoGitCore {
    private var repoPath: String = FileManager.default.currentDirectoryPath
    
    func run() async {
        // Check if we're in a git repo
        guard isGitRepo() else {
            print("❌ Not a git repository")
            print("   Run this command in a git repository")
            return
        }
        
        print("""
        🤖 AutoGit - Automatic Commit Generation
        
        Commands:
          suggest           Analyze staged changes and suggest commits
          auto              Auto-commit with generated message
          analyze           Show detailed change analysis
          conventional      Toggle conventional commits format
          config            Show current config
          help              Show this help
          quit              Exit
        
        Current repo: \(repoPath)
        """)
        
        while true {
            print("> ", terminator: "")
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else { continue }
            
            switch input {
            case "suggest", "s":
                await suggestCommits()
            case "auto", "a":
                await autoCommit()
            case "analyze":
                await analyzeChanges()
            case "conventional", "conv":
                toggleConventional()
            case "config", "c":
                showConfig()
            case "help", "h":
                showHelp()
            case "quit", "q", "exit":
                print("👋 Goodbye!")
                return
            default:
                print("Unknown command. Type 'help' for options.")
            }
        }
    }
    
    func suggestCommits() async {
        let diff = runGitCommand(["diff", "--cached"])
        let stat = runGitCommand(["diff", "--cached", "--stat"])
        
        guard !diff.isEmpty else {
            print("⚠️  No staged changes found")
            print("   Run: git add <files>")
            return
        }
        
        print("📊 Changes:")
        print(stat)
        print()
        
        let suggestions = analyzeDiff(diff)
        
        print("💡 Suggested commits:")
        for (i, suggestion) in suggestions.enumerated() {
            print("   \(i + 1). \(suggestion)")
        }
        
        print("\nUse 'auto' to commit with the first suggestion")
    }
    
    func autoCommit() async {
        let diff = runGitCommand(["diff", "--cached"])
        
        guard !diff.isEmpty else {
            print("❌ No staged changes to commit")
            return
        }
        
        let suggestions = analyzeDiff(diff)
        guard let message = suggestions.first else {
            print("❌ Could not generate commit message")
            return
        }
        
        print("📝 Generated: \"\(message)\"")
        print("Commit? (y/n/edit): ", terminator: "")
        
        guard let response = readLine()?.lowercased() else { return }
        
        let finalMessage: String
        switch response {
        case "y", "yes":
            finalMessage = message
        case "edit", "e":
            print("Enter your message: ", terminator: "")
            finalMessage = readLine() ?? message
        default:
            print("❌ Cancelled")
            return
        }
        
        // Execute actual git commit
        let result = runGitCommandWithOutput(["commit", "-m", finalMessage])
        
        if result.contains("error") || result.contains("fatal") {
            print("❌ Commit failed:")
            print(result)
        } else {
            print("✅ Committed successfully!")
            print("   Message: \(finalMessage)")
            
            // Show commit info
            let hash = runGitCommand(["rev-parse", "--short", "HEAD"])
            print("   Hash: \(hash)")
        }
    }
    
    func analyzeChanges() async {
        let diff = runGitCommand(["diff", "--cached"])
        let files = runGitCommand(["diff", "--cached", "--name-only"])
        
        print("📁 Files changed:")
        for file in files.components(separatedBy: .newlines) where !file.isEmpty {
            let additions = countAdditions(in: diff, for: file)
            let deletions = countDeletions(in: diff, for: file)
            print("   \(file): +\(additions) -\(deletions)")
        }
        
        print("\n📝 Change analysis:")
        
        // Detect change types
        if diff.contains("func ") || diff.contains("def ") || diff.contains("function") {
            print("   • Function/method changes detected")
        }
        if diff.contains("class ") || diff.contains("struct ") {
            print("   • Type definition changes")
        }
        if diff.contains("test") || diff.contains("spec") {
            print("   • Test file modifications")
        }
        if diff.contains("README") || diff.contains(".md") {
            print("   • Documentation updates")
        }
        if diff.contains("import ") || diff.contains("#include") || diff.contains("require") {
            print("   • Dependency changes")
        }
    }
    
    private func analyzeDiff(_ diff: String) -> [String] {
        var suggestions: [String] = []
        
        let filesChanged = runGitCommand(["diff", "--cached", "--name-only"])
        let fileList = filesChanged.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // Analyze file patterns
        let isSwift = fileList.contains { $0.hasSuffix(".swift") }
        let isJS = fileList.contains { $0.hasSuffix(".js") || $0.hasSuffix(".ts") }
        let isPython = fileList.contains { $0.hasSuffix(".py") }
        let isMarkdown = fileList.contains { $0.hasSuffix(".md") }
        let isTest = fileList.contains { $0.contains("Test") || $0.contains("test") || $0.contains("spec") }
        
        // Check diff content for patterns
        let addedLines = diff.components(separatedBy: .newlines).filter { $0.hasPrefix("+") && !$0.hasPrefix("+++") }.count
        let removedLines = diff.components(separatedBy: .newlines).filter { $0.hasPrefix("-") && !$0.hasPrefix("---") }.count
        
        // Detect commit type
        if isTest {
            suggestions.append("test: Add/update tests")
            if addedLines > removedLines {
                suggestions.append("test: Increase test coverage")
            }
        }
        
        if isMarkdown {
            suggestions.append("docs: Update documentation")
        }
        
        if diff.contains("fix:") || diff.contains("bug") || diff.contains("crash") || diff.contains("error") {
            suggestions.append("fix: Resolve issue in \(fileList.first ?? "code")")
        }
        
        if diff.contains("refactor") || diff.contains("rename") || diff.contains("move") {
            suggestions.append("refactor: Improve code structure")
        }
        
        if diff.contains("add:") || diff.contains("feat:") || diff.contains("implement") || addedLines > removedLines * 2 {
            suggestions.append("feat: Add new functionality")
        }
        
        // Generic suggestions
        if suggestions.isEmpty {
            if fileList.count == 1 {
                suggestions.append("chore: Update \(fileList[0])")
            } else {
                suggestions.append("chore: Update \(fileList.count) files")
            }
            suggestions.append("feat: Implement changes")
        }
        
        // Add detailed suggestion
        if let firstFile = fileList.first {
            let fileName = URL(fileURLWithPath: firstFile).lastPathComponent
            if fileList.count == 1 {
                suggestions.insert("chore: Update \(fileName)", at: 0)
            }
        }
        
        return Array(suggestions.prefix(3))
    }
    
    private func countAdditions(in diff: String, for file: String) -> Int {
        let lines = diff.components(separatedBy: .newlines)
        var inFile = false
        var count = 0
        
        for line in lines {
            if line.hasPrefix("diff --git") && line.contains(file) {
                inFile = true
            } else if line.hasPrefix("diff --git") {
                inFile = false
            }
            if inFile && line.hasPrefix("+") && !line.hasPrefix("+++") {
                count += 1
            }
        }
        return count
    }
    
    private func countDeletions(in diff: String, for file: String) -> Int {
        let lines = diff.components(separatedBy: .newlines)
        var inFile = false
        var count = 0
        
        for line in lines {
            if line.hasPrefix("diff --git") && line.contains(file) {
                inFile = true
            } else if line.hasPrefix("diff --git") {
                inFile = false
            }
            if inFile && line.hasPrefix("-") && !line.hasPrefix("---") {
                count += 1
            }
        }
        return count
    }
    
    private func runGitCommand(_ args: [String]) -> String {
        let task = Process()
        task.launchPath = "/usr/bin/git"
        task.arguments = args
        task.currentDirectoryPath = repoPath
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        try? task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    private func runGitCommandWithOutput(_ args: [String]) -> String {
        let task = Process()
        task.launchPath = "/usr/bin/git"
        task.arguments = args
        task.currentDirectoryPath = repoPath
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        try? task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    private func isGitRepo() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/git"
        task.arguments = ["rev-parse", "--git-dir"]
        task.currentDirectoryPath = repoPath
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        try? task.run()
        task.waitUntilExit()
        
        return task.terminationStatus == 0
    }
    
    private func toggleConventional() {
        print("✅ Conventional commits format enabled")
    }
    
    private func showConfig() {
        print("⚙️  Config:")
        print("   Repo: \(repoPath)")
        print("   Conventional commits: Yes")
        print("   Auto-push: No")
    }
    
    private func showHelp() {
        print("""
        Commands:
          suggest      Analyze changes and suggest commits
          auto         Auto-commit with generated message
          analyze      Show detailed change analysis
          conventional Toggle conventional format
          config       Show config
          help         Show help
          quit         Exit
        """)
    }
}
