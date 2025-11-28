# Contributing

Thank you for your interest in contributing to this project!

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests locally:
   ```bash
   terraform fmt -check -recursive
   terraform init -backend=false
   terraform validate
   tflint --init && tflint
   ```
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Code Style

- Use `terraform fmt` for formatting
- Follow [Terraform naming conventions](https://www.terraform-best-practices.com/naming)
- Add descriptions to all variables and outputs
- Update README.md if adding new features

## Reporting Issues

- Use GitHub Issues for bug reports and feature requests
- Include Terraform version and provider versions
- Provide minimal reproduction steps

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
