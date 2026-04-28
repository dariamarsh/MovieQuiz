import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    // MARK: - IBOutlets
    
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    
    // MARK: - State
    
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter = AlertPresenter()
    private var statisticService: StatisticServiceProtocol!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        questionFactory = QuestionFactory(delegate: self)
        questionFactory?.requestNextQuestion()
        statisticService = StatisticService()
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }

        currentQuestion = question
        let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
            self?.setButtonsEnabled(true)
        }
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
        guard let currentQuestion = currentQuestion else {
            return
        }
        setButtonsEnabled(false)
        let isCorrect = isYes == currentQuestion.correctAnswer
        showAnswerResult(isCorrect: isCorrect)
    }
    
    private func showCurrentQuestion() {
        questionFactory?.requestNextQuestion()
        setButtonsEnabled(true)
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.imageView.layer.borderWidth = 0
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            showResults()
        } else {
            currentQuestionIndex += 1
            showCurrentQuestion()
        }
    }
    
    private func showResults() {
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        let bestGameDateString = statisticService.bestGame.date.dateTimeString
        let message = """
        Ваш результат: \(correctAnswers)/\(questionsAmount)
        Количество сыгранных квизов: \(statisticService.gamesCount)
        Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(bestGameDateString))
        Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
        """
        let viewModel = QuizResultsViewModel(
            title: "Этот раунд окончен!",
            text: message,
            buttonText: "Сыграть ещё раз"
        )
               
        let model = AlertModel(
            title: viewModel.title,
            message: viewModel.text,
            buttonText: viewModel.buttonText
        ) { [weak self] in
            guard let self = self else { return }
                   
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
                   
            self.questionFactory?.requestNextQuestion()
            self.setButtonsEnabled(true)
        }
               
        alertPresenter.show(in: self, model: model)
    }
    
    private func setButtonsEnabled(_ isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
    }
}
