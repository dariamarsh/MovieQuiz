import UIKit

final class MovieQuizViewController: UIViewController {
    // MARK: - IBOutlets
    
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    
    // MARK: - State
    
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private let questions = QuizQuestion.mock
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showCurrentQuestion()
    }
    
    // MARK: - Actions
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        answer(isYes: false)
    }
    
    @IBAction private func yesButtonClicked(_ sender: Any) {
        answer(isYes: true)
    }
    
    // MARK: - Private Methods
    
    private func answer(isYes: Bool) {
        setButtonsEnabled(false)
        let currentQuestion = questions[currentQuestionIndex]
        let isCorrect = isYes == currentQuestion.correctAnswer
        showAnswerResult(isCorrect: isCorrect)
    }
    
    private func showCurrentQuestion() {
        let currentQuestion = questions[currentQuestionIndex]
        let viewModel = convert(model: currentQuestion)
        show(quiz: viewModel)
        setButtonsEnabled(true)
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questions.count)"
        )
    }
    
    private func show(quiz step: QuizStepViewModel) {
        textLabel.text = step.question
        imageView.image = step.image
        counterLabel.text = step.questionNumber
        
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 0
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect
        ? UIColor.ypGreen.cgColor
        : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questions.count - 1 {
            showResults()
        } else {
            currentQuestionIndex += 1
            showCurrentQuestion()
        }
    }
    
    private func showResults() {
        let text = "Ваш результат: \(correctAnswers)/\(questions.count)"
        
        let viewModel = QuizResultsViewModel(
            title: "Этот раунд окончен!",
            text: text,
            buttonText: "Сыграть ещё раз"
        )
        
        let alert = UIAlertController(
            title: viewModel.title,
            message: viewModel.text,
            preferredStyle: .alert
        )
        
        let action = UIAlertAction(title: viewModel.buttonText, style: .default) { _ in
            self.restartGame()
        }
        
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    private func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        showCurrentQuestion()
    }
    
    private func setButtonsEnabled(_ isEnabled: Bool) {
            yesButton.isEnabled = isEnabled
            noButton.isEnabled = isEnabled
        }
}
